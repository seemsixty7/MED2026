"""Tiny AutoLISP subset interpreter used to desk-test the pure geometry in
Support/MED3DPath.lsp outside AutoCAD. Dynamic scoping, case-insensitive symbols,
AutoLISP integer division, dotted pairs. foreach does NOT restore its variable
(stricter than AutoCAD) so shadowing bugs show up here."""
import math, re

class Sym(str):
    pass

class Pair:
    def __init__(self, car, cdr): self.car, self.cdr = car, cdr
    def __eq__(self, o): return isinstance(o, Pair) and lequal(self.car, o.car) and lequal(self.cdr, o.cdr)
    def __repr__(self): return f"({self.car!r} . {self.cdr!r})"

class LispError(Exception):
    pass

NIL = None
def truthy(v): return not (v is None or v == [] or v is False)
def lb(v): return True if v else None

def tokenize(src):
    toks, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c in ' \t\r\n': i += 1
        elif c == ';':
            while i < n and src[i] != '\n': i += 1
        elif c in "()'": toks.append(c); i += 1
        elif c == '"':
            j, buf = i + 1, []
            while src[j] != '"':
                if src[j] == '\\':
                    j += 1; buf.append({'n': '\n', 't': '\t'}.get(src[j], src[j]))
                else: buf.append(src[j])
                j += 1
            toks.append(('STR', ''.join(buf))); i = j + 1
        else:
            j = i
            while j < n and src[j] not in ' \t\r\n()\';"': j += 1
            toks.append(src[i:j]); i = j
    return toks

def atom(t):
    if isinstance(t, tuple): return t[1]
    if re.fullmatch(r'[+-]?\d+', t): return int(t)
    try: return float(t)
    except ValueError: return Sym(t.upper())

def parse(toks):
    pos = 0
    def rd():
        nonlocal pos
        t = toks[pos]; pos += 1
        if t == '(':
            out = []
            while toks[pos] != ')':
                if toks[pos] == '.':
                    pos += 1; cdr = rd(); pos += 1  # skip ')'
                    return Pair(out[0], cdr) if len(out) == 1 else out  # only simple pairs used
                out.append(rd())
            pos += 1
            return out
        if t == "'": return [Sym('QUOTE'), rd()]
        return atom(t)
    forms = []
    while pos < len(toks):
        if toks[pos] == ')': raise SyntaxError(f'unbalanced ) at token {pos} after form {len(forms)}')
        forms.append(rd())
    return forms

def lequal(a, b, fuzz=0.0):
    if isinstance(a, (int, float)) and isinstance(b, (int, float)): return abs(a - b) <= fuzz
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(lequal(x, y, fuzz) for x, y in zip(a, b))
    if (a in (None, [])) and (b in (None, [])): return True
    return a == b

def car(x):
    if x is None or x == []: return None
    return x.car if isinstance(x, Pair) else x[0]
def cdr(x):
    if x is None or x == []: return None
    if isinstance(x, Pair): return x.cdr
    r = x[1:]; return r if r else None
def cons(a, b):
    if b is None: return [a]
    if isinstance(b, list): return [a] + b
    return Pair(a, b)
def aslist(x): return [] if x is None else x

class Func:
    def __init__(self, params, locals_, body, name=''):
        self.params, self.locals, self.body, self.name = params, locals_, body, name

class Interp:
    def __init__(self):
        self.g = {}
        self.frames = []
        self.g['PI'] = math.pi
        self.g['T'] = True
        self.g['NIL'] = None
        self._builtins()

    def lookup(self, s):
        for f in reversed(self.frames):
            if s in f: return f[s]
        return self.g.get(s)
    def set(self, s, v):
        for f in reversed(self.frames):
            if s in f: f[s] = v; return
        self.g[s] = v

    def _builtins(self):
        B = self.g
        def num_div(*a):
            r = a[0]
            for x in a[1:]:
                if isinstance(r, int) and isinstance(x, int): r = int(r / x)
                else: r = r / x
            return r
        B['+'] = lambda *a: sum(a) if a else 0
        B['-'] = lambda *a: -a[0] if len(a) == 1 else a[0] - sum(a[1:])
        def mul(*a):
            r = 1
            for x in a: r *= x
            return r
        B['*'] = mul; B['/'] = num_div
        def chain(op):
            return lambda *a: lb(all(op(a[i], a[i + 1]) for i in range(len(a) - 1)))
        def eqv(x, y):
            if isinstance(x, (int, float)) and isinstance(y, (int, float)): return x == y
            return x == y
        B['='] = chain(eqv); B['/='] = lambda a, b: lb(not eqv(a, b))
        B['<'] = chain(lambda x, y: x < y); B['>'] = chain(lambda x, y: x > y)
        B['<='] = chain(lambda x, y: x <= y); B['>='] = chain(lambda x, y: x >= y)
        B['ABS'] = abs; B['SQRT'] = lambda x: math.sqrt(x); B['SIN'] = math.sin; B['COS'] = math.cos
        B['ATAN'] = lambda y, x=None: math.atan(y) if x is None else math.atan2(y, x)
        B['EXPT'] = lambda a, b: a ** b
        B['MIN'] = lambda *a: min(a); B['MAX'] = lambda *a: max(a)
        B['FIX'] = lambda x: int(x); B['FLOAT'] = lambda x: float(x)
        B['REM'] = lambda a, b: math.fmod(a, b) if isinstance(a, float) or isinstance(b, float) else int(math.fmod(a, b))
        B['1+'] = lambda x: x + 1; B['1-'] = lambda x: x - 1
        B['MINUSP'] = lambda x: lb(x < 0); B['ZEROP'] = lambda x: lb(x == 0)
        B['NUMBERP'] = lambda x: lb(isinstance(x, (int, float)) and not isinstance(x, bool))
        B['LISTP'] = lambda x: lb(x is None or isinstance(x, (list, Pair)))
        B['NULL'] = lambda x: lb(not truthy(x)); B['NOT'] = B['NULL']
        B['CAR'] = car; B['CDR'] = cdr
        B['CADR'] = lambda x: car(cdr(x)); B['CDDR'] = lambda x: cdr(cdr(x))
        B['CADDR'] = lambda x: car(cdr(cdr(x))); B['CADDDR'] = lambda x: car(cdr(cdr(cdr(x))))
        B['NTH'] = lambda n, l: (aslist(l)[n] if l is not None and n < len(aslist(l)) else None)
        B['LAST'] = lambda l: aslist(l)[-1] if l else None
        B['LENGTH'] = lambda l: len(aslist(l))
        B['REVERSE'] = lambda l: list(reversed(aslist(l))) or None
        B['APPEND'] = lambda *ls: sum((aslist(l) for l in ls), []) or None
        B['CONS'] = cons; B['LIST'] = lambda *a: list(a) if a else None
        def assoc(k, al):
            for it in aslist(al):
                if lequal(car(it), k): return it
            return None
        B['ASSOC'] = assoc
        def member(x, l):
            ls = aslist(l)
            for i, y in enumerate(ls):
                if lequal(y, x): return ls[i:]
            return None
        B['MEMBER'] = member
        B['VL-REMOVE'] = lambda x, l: [y for y in aslist(l) if not lequal(y, x)] or None
        B['EQUAL'] = lambda a, b, f=0.0: lb(lequal(a, b, f))
        B['EQ'] = lambda a, b: lb(a is b or (a == b and not isinstance(a, list)))
        B['DISTANCE'] = lambda p, q: math.sqrt(sum((a - b) ** 2 for a, b in zip(p, q)))
        B['LOGAND'] = lambda *a: __import__('functools').reduce(lambda x, y: x & y, a)
        B['STRCAT'] = lambda *a: ''.join(a); B['ITOA'] = lambda i: str(i)
        B['RTOS'] = lambda x, m=2, p=4: f"{x:.{p}f}"
        B['PRINC'] = lambda *a: a[0] if a else None
        B['VL-LOAD-COM'] = lambda: None
        B['BOUNDP'] = lambda s: lb(self.lookup(s) is not None)
        B['TYPE'] = lambda x: Sym('STR') if isinstance(x, str) else (Sym('INT') if isinstance(x, int) else Sym('REAL'))
        B['MAPCAR'] = lambda f, *ls: [self.apply(f, list(a)) for a in zip(*map(aslist, ls))] or None
        B['APPLY'] = lambda f, l: self.apply(f, aslist(l))

    def fn(self, f):
        if isinstance(f, Sym): f = self.lookup(f)
        if isinstance(f, list) and f and f[0] == 'LAMBDA': f = self.eval(f)  # '(lambda ...)
        if f is None: raise LispError('no function')
        return f

    def apply(self, f, args):
        f = self.fn(f)
        if callable(f): return f(*args)
        frame = {}
        for i, p in enumerate(f.params): frame[p] = args[i] if i < len(args) else None
        if len(args) != len(f.params): raise LispError(f"{f.name}: too few/many arguments")
        for l in f.locals: frame[l] = None
        self.frames.append(frame)
        try:
            r = None
            for b in f.body: r = self.eval(b)
            return r
        finally:
            self.frames.pop()

    def eval(self, x):
        if isinstance(x, Sym):
            if x == 'T': return True
            if x == 'NIL': return None
            return self.lookup(x)
        if not isinstance(x, list): return x
        if not x: return None
        h = x[0]
        if isinstance(h, Sym):
            if h == 'QUOTE': return x[1]
            if h == 'FUNCTION': return self.eval(x[1]) if isinstance(x[1], list) else x[1]
            if h == 'SETQ':
                v = None
                for i in range(1, len(x), 2):
                    v = self.eval(x[i + 1]); self.set(x[i], v)
                return v
            if h == 'DEFUN':
                name, args, body = x[1], x[2] or [], x[3:]
                if '/' in args:
                    k = args.index('/'); params, locs = args[:k], args[k + 1:]
                else: params, locs = args, []
                if any(v in ('T', 'NIL', 'PI') for v in params + locs):
                    raise LispError(f'{name}: T / NIL / PI cannot be an argument or local (AutoLISP protects them)')
                self.g[name] = Func(params, locs, body, name); return name
            if h == 'LAMBDA':
                args = x[1] or []
                if '/' in args:
                    k = args.index('/'); params, locs = args[:k], args[k + 1:]
                else: params, locs = args, []
                return Func(params, locs, x[2:], 'lambda')
            if h == 'IF':
                if truthy(self.eval(x[1])): return self.eval(x[2])
                return self.eval(x[3]) if len(x) > 3 else None
            if h == 'COND':
                for cl in x[1:]:
                    v = self.eval(cl[0])
                    if truthy(v):
                        for e in cl[1:]: v = self.eval(e)
                        return v
                return None
            if h == 'PROGN':
                r = None
                for e in x[1:]: r = self.eval(e)
                return r
            if h == 'AND':
                for e in x[1:]:
                    if not truthy(self.eval(e)): return None
                return True
            if h == 'OR':
                for e in x[1:]:
                    if truthy(self.eval(e)): return True
                return None
            if h == 'WHILE':
                r = None
                while truthy(self.eval(x[1])):
                    for e in x[2:]: r = self.eval(e)
                return r
            if h == 'REPEAT':
                r = None
                for _ in range(self.eval(x[1])):
                    for e in x[2:]: r = self.eval(e)
                return r
            if h == 'FOREACH':
                r = None; lst = aslist(self.eval(x[2]))
                self.frames.append({x[1]: None})   # AutoLISP: the foreach symbol is local
                try:
                    for it in lst:
                        self.frames[-1][x[1]] = it
                        for e in x[3:]: r = self.eval(e)
                finally:
                    self.frames.pop()
                return r
        f = self.eval(h) if isinstance(h, list) else self.lookup(h)
        if f is None: raise LispError(f"undefined function {h}")
        return self.apply(f, [self.eval(a) for a in x[1:]])

    def load(self, path):
        for form in parse(tokenize(open(path, encoding='latin-1').read())):
            self.eval(form)

def to_py(v):
    if isinstance(v, list): return [to_py(i) for i in v]
    if isinstance(v, Pair): return (to_py(v.car), to_py(v.cdr))
    return v
