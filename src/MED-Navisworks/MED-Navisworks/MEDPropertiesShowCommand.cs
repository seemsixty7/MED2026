using Autodesk.Navisworks.Api.Plugins;

namespace MEDNavisworks
{
    /// <summary>
    /// Add-in command to show the MED Properties dock pane.
    /// </summary>
    [Plugin("MEDPropertiesShow", "MED",
        DisplayName = "MED Properties",
        ToolTip = "Open the MED Properties dock pane.")]
    [AddInPlugin(AddInLocation.AddIn)]
    public class MEDPropertiesShowCommand : AddInPlugin
    {
        public override int Execute(params string[] parameters)
        {
            // PluginAttribute name + "." + developerId
            PluginRecord record =
                Autodesk.Navisworks.Api.Application.Plugins.FindPlugin("MEDPropertiesPlugin.MED");
            if (record == null)
                return 0;

            DockPanePluginRecord dockRecord = record as DockPanePluginRecord;
            if (dockRecord == null)
                return 0;

            if (!dockRecord.IsLoaded)
                dockRecord.LoadPlugin();

            DockPanePlugin pane = dockRecord.LoadedPlugin as DockPanePlugin;
            if (pane != null)
            {
                pane.Visible = true;
                pane.ActivatePane();
            }
            return 0;
        }
    }
}
