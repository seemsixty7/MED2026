using System.Windows.Forms;
using Autodesk.Navisworks.Api.Plugins;

namespace MEDNavisworks
{
    /// <summary>
    /// Dockable "MED Properties" pane. Appears under View (Windows) after load.
    /// </summary>
    [Plugin("MEDPropertiesPlugin", "MED",
        DisplayName = "MED Properties",
        ToolTip = "Show MEDProperties (ObjectType, Size, Description, Tag, Length, Weight) for the selection.")]
    [DockPanePlugin(320, 360, AutoScroll = true, MinimumWidth = 240, MinimumHeight = 200)]
    public class MEDPropertiesDockPane : DockPanePlugin
    {
        public override Control CreateControlPane()
        {
            MEDPropertiesControl control = new MEDPropertiesControl();
            control.Dock = DockStyle.Fill;
            control.CreateControl();
            return control;
        }

        public override void DestroyControlPane(Control pane)
        {
            if (pane != null)
                pane.Dispose();
        }
    }
}
