using System;

namespace MEDNavisworks
{
    /// <summary>
    /// Field names written by AutoCAD MED as XData app MEDProperties
    /// (see MED-DotNet MedPropertiesXData.cs). Not BOM.
    /// </summary>
    internal static class MedPropertyKeys
    {
        public const string AppName = "MEDProperties";
        public const string CategoryDisplayName = "MEDProperties";
        /// <summary>Internal name used when attaching via COM SetUserDefined.</summary>
        public const string CategoryInternalName = "LcOaMEDProperties";

        public const string ObjectType = "ObjectType";
        public const string Size = "Size";
        public const string Description = "Description";
        public const string Tag = "Tag";
        public const string Length = "Length";
        public const string Weight = "Weight";

        public static readonly string[] All =
        {
            ObjectType, Size, Description, Tag, Length, Weight
        };

        /// <summary>
        /// Alternate labels the DWG reader / convert options may emit.
        /// </summary>
        public static readonly string[] AlternateCategoryNames =
        {
            "MEDProperties",
            "MED Properties",
            "LcOaMEDProperties",
            "User",
            "Element"
        };
    }
}
