using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

namespace MEDDotNet
{
    public sealed class Dwg3DThumbResult
    {
        public byte[] Png;              // normalized PNG bytes, null if none
        public string Format = "NONE";  // PNG, BMP, NONE
        public string Reason = "";
    }

    /// <summary>Reads the preview image embedded in a DWG file header (R13 .. R2018+). Port of tools\Dwg3DCatalog\DwgThumbnail.cs.</summary>
    public static class Dwg3DThumbnail
    {
        static readonly byte[] Sentinel = { 0x1F, 0x25, 0x6D, 0x07, 0xD4, 0x36, 0x28, 0x28, 0x9D, 0x57, 0xCA, 0x3F, 0x9D, 0x44, 0x10, 0x2B };

        public static Dwg3DThumbResult Extract(string path)
        {
            var r = new Dwg3DThumbResult();
            try
            {
                using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                using (var br = new BinaryReader(fs))
                {
                    long len = fs.Length;
                    if (len < 0x40) { r.Reason = "file too small"; return r; }
                    var ver = System.Text.Encoding.ASCII.GetString(br.ReadBytes(6));
                    if (!ver.StartsWith("AC10")) { r.Reason = "not a DWG (" + ver + ")"; return r; }
                    fs.Position = 0x0D;
                    int addr = br.ReadInt32();
                    if (addr <= 0 || addr + 21 > len) { r.Reason = "no image address"; return r; }
                    fs.Position = addr;
                    var s = br.ReadBytes(16);
                    for (int i = 0; i < Sentinel.Length; i++)
                        if (s.Length != Sentinel.Length || s[i] != Sentinel[i]) { r.Reason = "image sentinel not found"; return r; }
                    br.ReadInt32(); // overall size
                    int count = br.ReadByte();
                    if (count > 16) count = 16;
                    long pngStart = 0, bmpStart = 0; int pngSize = 0, bmpSize = 0; bool wmf = false;
                    for (int i = 0; i < count; i++)
                    {
                        byte code = br.ReadByte();
                        int start = br.ReadInt32();
                        int size = br.ReadInt32();
                        bool ok = start > 0 && size > 0 && (long)start + size <= len;
                        if (code == 6 && ok) { pngStart = start; pngSize = size; }
                        else if (code == 2 && ok) { bmpStart = start; bmpSize = size; }
                        else if (code == 3 && ok) wmf = true;
                    }
                    if (pngSize > 0)
                    {
                        fs.Position = pngStart;
                        var data = br.ReadBytes(pngSize);
                        if (data.Length > 8 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47)
                        {
                            r.Png = Normalize(data);
                            if (r.Png != null) { r.Format = "PNG"; return r; }
                        }
                        r.Reason = "PNG entry invalid";
                    }
                    if (bmpSize > 0)
                    {
                        fs.Position = bmpStart;
                        var dib = br.ReadBytes(bmpSize);
                        var png = DibToPng(dib);
                        if (png != null) { r.Png = png; r.Format = "BMP"; r.Reason = ""; return r; }
                        r.Reason = "BMP entry invalid";
                    }
                    if (r.Reason == "") r.Reason = wmf ? "WMF preview only" : (count == 0 ? "no preview images" : "empty preview");
                }
            }
            catch (Exception ex) { r.Reason = ex.GetType().Name + ": " + ex.Message; r.Png = null; r.Format = "NONE"; }
            return r;
        }

        static byte[] Normalize(byte[] png)
        {
            try
            {
                using (var ms = new MemoryStream(png))
                using (var img = Image.FromStream(ms))
                {
                    if (img.Width < 1 || img.Height < 1) return null;
                    return png;
                }
            }
            catch { return null; }
        }

        static byte[] DibToPng(byte[] dib)
        {
            if (dib.Length < 40) return null;
            int biSize = BitConverter.ToInt32(dib, 0);
            if (biSize < 12 || biSize > dib.Length) return null;
            int width = BitConverter.ToInt32(dib, 4), height = BitConverter.ToInt32(dib, 8);
            if (width <= 0 || height == 0) return null;
            int bitCount = BitConverter.ToUInt16(dib, 14);
            int compression = biSize >= 20 ? BitConverter.ToInt32(dib, 16) : 0;
            int clrUsed = biSize >= 36 ? BitConverter.ToInt32(dib, 32) : 0;
            int pal = clrUsed != 0 ? clrUsed : (bitCount <= 8 ? 1 << bitCount : 0);
            int masks = (compression == 3 && biSize == 40) ? 12 : 0;
            int offBits = 14 + biSize + masks + pal * 4;
            var file = new byte[14 + dib.Length];
            file[0] = (byte)'B'; file[1] = (byte)'M';
            BitConverter.GetBytes(file.Length).CopyTo(file, 2);
            BitConverter.GetBytes(offBits).CopyTo(file, 10);
            Buffer.BlockCopy(dib, 0, file, 14, dib.Length);
            try
            {
                using (var ms = new MemoryStream(file))
                using (var bmp = new Bitmap(ms))
                using (var outMs = new MemoryStream())
                {
                    bmp.Save(outMs, ImageFormat.Png);
                    return outMs.ToArray();
                }
            }
            catch { return null; }
        }

        public static Image FromPng(byte[] png)
        {
            if (png == null) return null;
            try
            {
                using (var ms = new MemoryStream(png))
                using (var img = Image.FromStream(ms))
                    return new Bitmap(img);
            }
            catch { return null; }
        }

        public static Image Scaled(Image src, int w, int h, Color back)
        {
            var bmp = new Bitmap(w, h);
            using (var g = Graphics.FromImage(bmp))
            {
                g.Clear(back);
                g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                if (src != null)
                {
                    double k = Math.Min((double)w / src.Width, (double)h / src.Height);
                    int dw = Math.Max(1, (int)(src.Width * k)), dh = Math.Max(1, (int)(src.Height * k));
                    g.DrawImage(src, (w - dw) / 2, (h - dh) / 2, dw, dh);
                }
            }
            return bmp;
        }

        public static Image Placeholder(int w, int h, string text)
        {
            var bmp = new Bitmap(w, h);
            using (var g = Graphics.FromImage(bmp))
            using (var pen = new Pen(Color.FromArgb(110, 110, 110), 1) { DashStyle = System.Drawing.Drawing2D.DashStyle.Dash })
            {
                g.Clear(Color.FromArgb(60, 60, 60));
                g.DrawRectangle(pen, 2, 2, w - 5, h - 5);
                float fsz = Math.Max(6f, Math.Min(w, h) / 9f);
                using (var f = new Font("Segoe UI", fsz, GraphicsUnit.Pixel))
                using (var sf = new StringFormat { Alignment = StringAlignment.Center, LineAlignment = StringAlignment.Center })
                    g.DrawString(text ?? "No preview", f, Brushes.Gainsboro, new RectangleF(0, 0, w, h), sf);
            }
            return bmp;
        }
    }
}
