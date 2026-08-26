MED_Change : dialog
{
  label = "MED Change";
  :row
  {
    :column
    {
      :text
      {
         label = "Select Tag to Edit";
      }
      :popup_list
      {
         key = "taglist";
         width = 24;
      }
      :button
      {
        label = "Add Conduit";
        key = "add_con";
      }
      :button
      {
        label = "Add Cable";
        key = "add_cab";
      }
      :button
      {
        label = "Add Tray";
        key = "add_try";
      }
      :button
      {
        label = "Add Fitting";
        key = "add_fit";
      }
      :button
      {
        label = "Add Equipment";
        key = "add_eqp";
      }
      :button
      {
        label = "Delete";
        key = "upd_del";
      }
      :toggle
      {
        label = "Measure On/Off";
        key = "edit_msr";
      }

    }
    :column
    {
      :spacer
      {
        width = 2;
      }
    }
    :boxed_column
    {
      label = "Selection values";
      :row
      {
        :boxed_column
        {
          :text
          {
            label = "Tag:";
          }
          :edit_box
          {
            key = "edit_tag";
            edit_limit = 12;
          }
        }
        :boxed_column
        {
          :text
          {
            key   = "rtag_txt";
            label = "Related Tag:";
          }
          :edit_box
          {
            key = "edit_rtag";
            edit_limit = 12;
          }
        }
      }
      :row
      {
        :boxed_column
        {
          :text
          {
            key = "size_txt";
            label = "Size:";
          }
          :popup_list
          {
            key = "edit_size";
          }
        }
        :boxed_column
        {
          :text
          { 
            key   = "alt_txt";
            label = "Alternate";
          }
          :popup_list
          {
            key = "edit_alt";
          }
        }
      }
      :row
      {
        :boxed_column
        {
          :text
          {
            key   = "dpth_txt";
            label = "Depth:";
          }
          :popup_list
          {
            key = "edit_dpth";
          }
        }
        :boxed_column
        {
          :text
          {
            key   = "dist_txt";
            label = "Distance:";
          }
          :edit_box
          {
            key = "edit_dist";
          }
        }
      }
      :popup_list
      {
        label = "Code";
        key = "edit_code";
        width = 60;
      }
      :text
      {
        key = "edit_text";
      }
    }
  }
  ok_cancel_help;
}

Med_ConSize : dialog
{
  label = "MED Conduit Size";
  :column
  {
    :boxed_radio_column
    {
      label = "Select Size";
      :radio_button
      {
        label = "1/2\"";
        key   = "sizea";
      }
      :radio_button
      {
        label = "3/4\"";
        key   = "sizeb";
      }
      :radio_button
      {
        label = "1\"";
        key   = "sizec";
      }
      :radio_button
      {
        label = "1-1/4\"";
        key   = "sized";
      }
      :radio_button
      {
        label = "1-1/2\"";
        key   = "sizee";
      }
      :radio_button
      {
        label = "2\"";
        key   = "sizef";
      }
      :radio_button
      {
        label = "2-1/2\"";
        key   = "sizeg";
      }
      :radio_button
      {
        label = "3\"";
        key   = "sizeh";
      }
      :radio_button
      {
        label = "3-1/2\"";
        key   = "sizei";
      }
      :radio_button
      {
        label = "4\"";
        key   = "sizej";
      }
      :radio_button
      {
        label = "5\"";
        key   = "sizek";
      }
      :radio_button
      {
        label = "6\"";
        key   = "sizel";
      }
    }
    ok_cancel;
  }
}

Med_Settings : dialog
{
  label = "MED Settings";
  :column
  {
    :toggle
    {
      label = "Conduit Bends";
      key = "conbend";
    }
    :toggle
    {
      label = "Size Override";
      key = "sizeovr";
    }
    :toggle
    {
      label = "User Rotate";
      key = "userrot";
    }
    :toggle
    {
      label = "Tagging";
      key = "tagging";
    }
    :toggle
    {
      label = "Vertical Tray";
      key = "verttray";
    }
    :edit_box
    {
      label = "Bend Multiplier";
      key = "bndmult";
      edit_limit = 12;
    }
    :edit_box
    {
      label = "Tray Tangent";
      key = "traytan";
      edit_limit = 12;
    }
  }
  ok_cancel;
}

Med_Details : dialog
{
  label = "Detail Tag Update";
  :column
  {
    :text
    {
      label="Detail                       | Current | Actual";
    }
    :list_box
    {
       key="detaglist";
       multiple_select=true;
    }
    :button
    {
       label="Update";
       key="updsel";
    }
    cancel_button;

  }
}


Med_bom : dialog
{
  label = "MED BOM Output";
  :column
  {
    :text
    {
      label="MED_TYPE         | MED_TAG      | MED_SIZE     | MED_DESC                                     ";
    }
    :list_box
    {
       key="bomlist";
       multiple_select = true;
    }
    :button
    {
       label="Make A Selection Set of this Entity";
       key="showitm";
    }

  }
  ok_button;
}

Med_bom1 : dialog
{
  label = "MED BOM";
  :row
  {
    :boxed_column
    {
      label = "Med Types";
      :toggle
      {
        label = "Conduits";
        key = "1conduits";
        value = "1";
      }
      :toggle
      {
        label = "Cables";
        key = "2cables";
        value = "1";
      }
      :toggle
      {
        label = "Trays";
        key = "3trays";
        value = "1";
      }
      :toggle
      {
        label = "Fittings";
        key = "4fittings";
        value = "1";
      }
      :toggle
      {
        label = "Equip/Details";
        key = "5equipment";
        value = "1";
      }
    }
  }
  ok_cancel;
}

Detail : dialog {
   label = "Detail Insert";
   : column {
       : button {
           label = "Lighting";
           key = "light";
       }
       : button {
           label = "Grounding";
           key = "ground";
       }
       : button {
           label = "Power";
           key = "power";
       }
       : button {
           label = "Instrumentation";
           key = "instrument";
       }
       : button {
           label = "Cable Tray";
           key = "tray";
       }
   }
   cancel_button;
}

DetailInsert : dialog
{
  label = "Select Detail";
  key = "detailtype";
  :row
  {
    :column
    {
      :list_box
      {
         key="detaillist";
         width = 50;
      }
    }
    :column
    {

      :image
      {
        key = "detail_sym";
        color = 0;
        width = 23;
      }


    }
  }
  ok_cancel;
}

Med_type : dialog
{
  label = "Main Electrical Data Type Database";
  :column
  {
    :text
    {
      label="MED_TYPE    | CODE | MED_DESC                                     ";
    }
    :list_box
    {
       key="typelist";
       multiple_select = false;
       value = "0";
    }
    :row
    {
       : button {
           label = "Modify Record";
           key = "Modify";
       }
       : button {
           label = "Add New Record";
           key = "Addnew";
       }
    }

  }
  ok_button;
}

Med_TypeEdit : dialog
{
  label = "MED Type Edit Dialog";
  :column
  {
    :row
    {
      :text
      {
        label = "MED_CONDUIT";
        key   = "edit_type";
      }
      :edit_box
      {
        label = "Code:";
        key   = "Editcode";
        edit_limit = 5;
      }
      :edit_box
      {
        label = "Group";
        key   = "Groupcode";
        edit_limit = 11;
      }
    }
    :row
    {
      :text
      {
        label = "Description:";
      }
    }
    :row
    {
      :edit_box
      {
        key   = "Editdesc";
        edit_limit =99;
        width = 60;

      }
    }
    :row
    {
      :edit_box
      {
        label = "Key1:";
        key   = "Editkey1";
        edit_limit = 20;
      }
      :edit_box
      {
        label = "Key2:";
        key   = "Editkey2";
        edit_limit = 20;
      }

    }
    :row
    {
      :edit_box
      {
        label = "Key3:";
        key   = "Editkey3";
        edit_limit = 20;
      }
      :edit_box
      {
        label = "Key4:";
        key   = "Editkey4";
        edit_limit = 20;
      }

    }
    :row
    {
      :edit_box
      {
        label = "User1:";
        key   = "Editusr1";
        edit_limit = 20;
      }
      :edit_box
      {
        label = "User2:";
        key   = "Editusr2";
        edit_limit = 20;
      }

    }
    :row
    {
      :edit_box
      {
        label = "User3:";
        key   = "Editusr3";
        edit_limit = 20;
      }
      :edit_box
      {
        label = "User4:";
        key   = "Editusr4";
        edit_limit = 20;
      }

    }

  }
  ok_cancel;
}

Med_TypeAdd : dialog
{
  label = "MED Type Add Dialog";
  :row
  {
    :boxed_radio_column
    {
       label = "Select Type:";
       value = "CONDUIT";
       key = "new_type";
       :radio_button
       {
          label="CONDUIT";
          key = "CONDUIT";
       }
       :radio_button
       {
          label="CABLE";
          key = "CABLE";
       }
       :radio_button
       {
          label="TRAY";
          key = "TRAY";
       }
       :radio_button
       {
          label="FITTING";
          key = "FITTING";
       }
       :radio_button
       {
          label="EQUIP";
          key = "EQUIP";
       }
    }
    :column
    {
      :row
      {
        :edit_box
        {
          label = "Code:";
          key   = "Editcode";
          edit_limit = 5;
        }
        :edit_box
        {
          label = "Group";
          key   = "Groupcode";
          edit_limit = 11;
        }
      }
      :row
      {
        :text
        {
          label = "Description:";
        }
      }
      :row
      {
        :edit_box
        {
          key   = "Editdesc";
          edit_limit =99;
          width = 60;
    
        }
      }
      :row
      {
        :edit_box
        {
          label = "Key1:";
          key   = "Editkey1";
          edit_limit = 20;
        }
        :edit_box
        {
          label = "Key2:";
          key   = "Editkey2";
          edit_limit = 20;
        }
    
      }
      :row
      {
        :edit_box
        {
          label = "Key3:";
          key   = "Editkey3";
          edit_limit = 20;
        }
        :edit_box
        {
          label = "Key4:";
          key   = "Editkey4";
          edit_limit = 20;
        }
    
      }
      :row
      {
        :edit_box
        {
          label = "User1:";
          key   = "Editusr1";
          edit_limit = 20;
        }
        :edit_box
        {
          label = "User2:";
          key   = "Editusr2";
          edit_limit = 20;
        }
    
      }
      :row
      {
        :edit_box
        {
          label = "User3:";
          key   = "Editusr3";
          edit_limit = 20;
        }
        :edit_box
        {
          label = "User4:";
          key   = "Editusr4";
          edit_limit = 20;
        }
    
      }
    
    }
  }
  ok_cancel;
}
MED_setup : dialog
{
   label = "Drawing Setup";
   :boxed_radio_row
   {
     label = "Drawing Scale Type";
     :radio_button
     {
        label = "Full Size 1=1";
        key = "Full";
     }
     :radio_button
     {
        label = "Architectual";
        key = "A00";
     }
     :radio_button
     {
        label = "Engineering";
        key = "E00";
     }
   :radio_button
     {
        label = "Metric";
        key = "M00";
     }
   }
   :row
   {
     :boxed_radio_column
     {
       key = "Arch";
       :radio_button
       {
         label = "3\"     = 1'-0\"";
         key   = "A4";
       }
       :radio_button
       {
         label = "1-1/2\" = 1'-0\"";
         key   = "A8";
       }
       :radio_button
       {
         label = "1\"     = 1'-0\"";
         key   = "A12";
       }
       :radio_button
       {
         label = "3/4\"   = 1'-0\"";
         key   = "A16";
       }
       :radio_button
       {
         label = "1/2\"   = 1'-0\"";
         key   = "A24";
       }
       :radio_button
       {
         label = "3/8\"   = 1'-0\"";
         key   = "A32";
       }
       :radio_button
       {
         label = "1/4\"   = 1'-0\"";
         key   = "A48";
       }
       :radio_button
       {
         label = "3/16\"  = 1'-0\"";
         key   = "A64";
       }
       :radio_button
       {
         label = "1/8\"   = 1'-0\"";
         key   = "A96";
       }
       :radio_button
       {
         label = "3/32\"  = 1'-0\"";
         key   = "A128";
       }
       :radio_button
       {
         label = "1/16\"  = 1'-0\"";
         key   = "A192";
       }

     }
     :boxed_radio_column
     {
       key = "Eng";
       :radio_button
       {
         label = "1\" = 10'-0\"";
         key   = "E120";
       }
       :radio_button
       {
         label = "1\" = 20'-0\"";
         key   = "E240";
       }
       :radio_button
       {
         label = "1\" = 30'-0\"";
         key   = "E360";
       }
       :radio_button
       {
         label = "1\" = 40'-0\"";
         key   = "E480";
       }
       :radio_button
       {
         label = "1\" = 50'-0\"";
         key   = "E600";
       }
       :radio_button
       {
         label = "1\" = 60'-0\"";
         key   = "E720";
       }
       :radio_button
       {
         label = "1\" = 100'-0\"";
         key   = "E1200";
       }
       :radio_button
       {
         label = "1\" = 200'-0\"";
         key   = "E2400";
       }

     }
   :boxed_radio_column
     {
       key = "Met";
       :radio_button
       {
         label = "1 = 1";
         key   = "M1";
       }
       :radio_button
       {
         label = "1 = 500";
         key   = "M500";
       }
       :radio_button
       {
         label = "1 = 1000";
         key   = "M1000";
       }
       :radio_button
       {
         label = "1 = 1250";
         key   = "M1250";
       }
       :radio_button
       {
         label = "1 = 1500";
         key   = "M1500";
       }
       :radio_button
       {
         label = "1 = 2000";
         key   = "M2000";
       }
       :radio_button
       {
         label = "1 = 2500";
         key   = "M2500";
       }
     }
   }
   :row
   {
     :text
     {
       label = "Title Block:";
     }
     :toggle
    {
      label = "Use PaperSpace";
      key = "usepaperspace";
    }
   }
   :row
   {
     :text
     {
       label = "Title Block";
       key   = "Title";
       width = 30;
     }
     :button
     {
       label = "File...";
       key   = "GetTitle";
     }
   }
   ok_cancel;
}

Med_TraySize : dialog
{
  label = "MED Tray Size";
  :row
  {
    :boxed_radio_column
    {
      label = "Width";
      :radio_button
      {
        label = "6\"";
        key   = "sizea";
      }
      :radio_button
      {
        label = "9\"";
        key   = "sizeb";
      }
      :radio_button
      {
        label = "12\"";
        key   = "sizec";
      }
      :radio_button
      {
        label = "18\"";
        key   = "sized";
      }
      :radio_button
      {
        label = "24\"";
        key   = "sizee";
      }
      :radio_button
      {
        label = "30\"";
        key   = "sizef";
      }
      :radio_button
      {
        label = "36\"";
        key   = "sizeg";
      }
      :radio_button
      {
        label = "42\"";
        key   = "sizeh";
      }
      :radio_button
      {
        label = "48\"";
        key   = "sizei";
      }
    }
    :column
    {
      :boxed_radio_column
      {
        label = "Depth";
        :radio_button
        {
          label = "3\"";
          key   = "deptha";
        }
        :radio_button
        {
          label = "4\"";
          key   = "depthb";
        }
        :radio_button
        {
          label = "6\"";
          key   = "depthc";
        }
      }
      :boxed_radio_column
      {
        label = "Radius";
        :radio_button
        {
          label = "12\"";
          key   = "radiusa";
        }
        :radio_button
        {
          label = "24\"";
          key   = "radiusb";
        }
        :radio_button
        {
          label = "36\"";
          key   = "radiusc";
        }
        :radio_button
        {
          label = "48\"";
          key   = "radiusd";
        }
      }

    }
  }
  ok_cancel;

}
Match_Text : dialog
{
  label = "Match Text";
  :column
  {
    :toggle
    {
      label = "Style";
      key = "mStyle";
    }
    :toggle
    {
      label = "Height";
      key = "mHeight";
    }
    :toggle
    {
      label = "Oblique";
      key = "mOblique";
    }
    :toggle
    {
      label = "Width";
      key = "mWidth";
    }
    :toggle
    {
      label = "Rotation";
      key = "mRotation";
    }
    :text
    {
      label = "Select Properties to Match";
    }
    
  }
  ok_cancel;
}


Med_CTEdit : dialog
{
  label = "Suffix / Prefix Editor";
  :row
  {
  :boxed_column
  {
    label = "Prefix";
    :row
    {
      :edit_box
      {
        label = "Text:";
        key   = "Prefix";
      }
    }
    :row
    {
      :edit_box
      {
        label = "Chars to Edit:";
        key   = "PEdit";

      }

    }
    :row
    {
      :toggle
      {
        label = "Auto";
        key = "PAuto";
      }
      :toggle
      {
        label = "Typical";
        key = "PTyp";
      }

    }
    :row
    {
      :edit_box
      {
        label = "Increment";
        key   = "PCounter";
      }
    }

  }
  :boxed_column
  {
    label = "Suffix";
    :row
    {
      :edit_box
      {
        label = "Text";
        key   = "Suffix";
      }
    }
    :row
    {
      :edit_box
      {
        label = "Chars to Edit";
        key   = "SEdit";

      }

    }
    :row
    {
      :toggle
      {
        label = "Auto";
        key = "SAuto";
      }
      :toggle
      {
        label = "Typical";
        key = "STyp";
      }
    }
    :row
    {
      :edit_box
      {
        label = "Increment";
        key   = "SCounter";
      }

    }

  }
  }
  ok_cancel;
}

Med_Cable : dialog
{
  label = "MED Cable";
  :row
  {
    :column
    {
      :list_box
      {
        label = "Code";
        key = "edit_code";
        width = 50;
        height = 20;
      }
    }
    :column
    {
      :spacer
      {
        height = 5;
      }
      :button
      {
        label = ">";
        key = "Addcab";
      }
      :button
      {
        label = "<";
        key = "Subcab";
      }
      :spacer
      {
        height = 10;
      }
    }
    :column
    {
      :list_box
      {
        label = "Cables used";
        key = "new_cables";
        width =50;
        height = 20;
      }
    }

  }
  ok_cancel_help;
}

Med_DDMEDlist : dialog
{
  label = "Dynamic MEDList";
  :column
  {
    :text
    {
      label="MED Data for Current Entity";
    }
    :list_box
    {
       key="meddatalist";
    }
    :row
    {
        :button
    	{
       	label="<-Previous";
       	key="selprev";
    	}
    	:button
    	{
       	label="Next->";
       	key="selnext";
    	}
    }
    :button
    {
    label="MEDCHG this Entity";
    key="medchg";
    }
    ok_only;

  }
}