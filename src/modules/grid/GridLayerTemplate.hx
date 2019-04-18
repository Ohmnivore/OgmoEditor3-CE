package modules.grid;

import level.data.Level;
import project.data.LayerTemplate;

class GridLayerTemplate extends LayerTemplate
{
  public var trimEmptyCells:Bool = true;
  public var legend:Map<String, Color>;
  public var transparent(get, never):String;
  public var firstSolid(get, never):String;

  public function new(exportID:String)
  {
    super(exportID);
    legend = new Map();
    legend.set("0", new Color(0, 0, 0, 0));
    legend.set("1", new Color(0, 0, 0, 1));
  }

  public var legendchars:String = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

  override function toString():String
  {
      var s = super.toString();
      for (key in legend.keys()) s += key + ": " + legend[key].rgbaString() + "\n";
      return s;
  }

  override function createEditor(id:Int)
  {
      return new GridLayerEditor(id);
  }

  override function createLayer(level: Level, id:Int)
  {
      return new GridLayer(level, id);
  }

  override function save():Dynamic
  {
      var data:Dynamic = super.save();
      data.legend = {};
      for (key in legend.keys()) Reflect.setField(data.legend, key, legend[key].toHexAlpha());
      return data;
  }

  override function load(data:Dynamic):LayerTemplate
  {
      super.load(data);

      legend = new Map();
      for (key in (cast data.legend : Array<String>))
          legend[key] = Color.fromHexAlpha(key);

      return this;
  }

  function get_transparent():String
  {
    for (s in legend.keys()) return s;
    throw "Grid Layers must have at least 2 characters in their legend.";
  }

  function get_firstSolid():String
  {
    var i = false;

    for (s in legend.keys()) 
    {
      if (i) return s;
      else i = true;
    }
    throw "Grid layers must have at least 2 characters in their legend.";
  }
}

// TODO
//definition
// (<any>window).startup.push(function()
// {
//     let tools:Tool[] = [
//         new GridPencilTool(),
//         new GridRectangleTool(),
//         new GridLineTool(),
//         new GridFloodTool(),
//         new GridEyedropperTool(),
//         new GridSelectionTool()
//     ];
//     let n = new LayerDefinition(GridLayerTemplate, GridLayerTemplateEditor, "grid", "layer-grid", "Grid Layer", tools, 0);
//     LayerDefinition.definitions.push(n);
// });