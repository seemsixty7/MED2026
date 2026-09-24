using System;
using System.IO;
using Autodesk.Navisworks.Api;
using Autodesk.Navisworks.Api.Plugins;

namespace MEDNavisworks
{
    /// <summary>
    /// Auto-load sibling .medprops.json when a document becomes active / models change.
    /// </summary>
    [Plugin("MEDPropertiesApp", "MED",
        DisplayName = "MED Properties App",
        ToolTip = "Auto-loads MEDProperties JSON sidecars for appended DWGs.")]
    public class MEDPropertiesAppPlugin : EventWatcherPlugin
    {
        Document _hooked;
        bool _busy;

        public override void OnLoaded()
        {
            Autodesk.Navisworks.Api.Application.ActiveDocumentChanged += OnActiveDocumentChanged;
            Hook(Autodesk.Navisworks.Api.Application.ActiveDocument);
            TryAuto(Autodesk.Navisworks.Api.Application.ActiveDocument);
        }

        public override void OnUnloading()
        {
            Autodesk.Navisworks.Api.Application.ActiveDocumentChanged -= OnActiveDocumentChanged;
            Unhook();
        }

        void OnActiveDocumentChanged(object sender, EventArgs e)
        {
            Hook(Autodesk.Navisworks.Api.Application.ActiveDocument);
            TryAuto(Autodesk.Navisworks.Api.Application.ActiveDocument);
        }

        void Hook(Document doc)
        {
            Unhook();
            _hooked = doc;
            if (_hooked == null)
                return;
            try { _hooked.Models.CollectionChanged += OnModelsChanged; } catch { }
            try { _hooked.FilesUpdated += OnFilesUpdated; } catch { }
        }

        void Unhook()
        {
            if (_hooked != null)
            {
                try { _hooked.Models.CollectionChanged -= OnModelsChanged; } catch { }
                try { _hooked.FilesUpdated -= OnFilesUpdated; } catch { }
                _hooked = null;
            }
        }

        void OnModelsChanged(object sender, EventArgs e)
        {
            TryAuto(_hooked ?? Autodesk.Navisworks.Api.Application.ActiveDocument);
        }

        void OnFilesUpdated(object sender, EventArgs e)
        {
            TryAuto(_hooked ?? Autodesk.Navisworks.Api.Application.ActiveDocument);
        }

        void TryAuto(Document doc)
        {
            if (_busy || doc == null)
                return;
            _busy = true;
            try
            {
                bool any = false;
                foreach (string path in MedPropsJsonLoader.CandidateJsonPaths(doc))
                {
                    if (File.Exists(path))
                    {
                        any = true;
                        break;
                    }
                }
                if (!any)
                    return;
                MedPropsJsonLoader.TryAutoLoad(doc);
            }
            catch
            {
                // best-effort
            }
            finally
            {
                _busy = false;
            }
        }
    }
}
