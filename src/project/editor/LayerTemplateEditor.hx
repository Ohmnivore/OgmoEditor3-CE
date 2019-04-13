package project.editor;

import js.jquery.JQuery;
import project.data.LayerTemplate;

class LayerTemplateEditor
{
  var into:JQuery;
  var template:LayerTemplate;
  var name:JQuery;
  var gridWidth:JQuery;
  var gridHeight:JQuery;
	var parentPanel:ProjectLayersPanel;

  public function new(template:LayerTemplate)
  {
    this.template = template;
  }

  /**
   * Originally `import`. Name changed to due to keyword being reserved in Haxe
   * @param into 
   */
  public function importInto(into:JQuery):Void
  {
    this.into = into;
    name = Fields.createField("Name", template.name);
    Fields.createSettingsBlock(into, name, SettingsBlock.Half, "Name", SettingsBlock.InlineTitle);

    name.on("input", function()
    {
      parentPanel.layersList.perform((n) ->
      {
        if (n.data == template) n.label  = name.val();
      });
    });
      
    gridWidth = Fields.createField("00", template.gridSize.x.toString());
    Fields.createSettingsBlock(into, gridWidth, SettingsBlock.Fourth, "Grid Width", SettingsBlock.InlineTitle);
      
    gridHeight = Fields.createField("00", template.gridSize.y.toString());
    Fields.createSettingsBlock(into, gridHeight, SettingsBlock.Fourth, "Grid Height", SettingsBlock.InlineTitle);
    Fields.createLineBreak(into);
  }

  public function save():Void
  {
    template.name = Fields.getField(name);
    template.gridSize.x = Import.integer(Fields.getField(gridWidth), 16);
    template.gridSize.y = Import.integer(Fields.getField(gridHeight), 16);
  }
}