package project.editor;

import js.html.Window;
import js.jquery.JQuery;
import util.ItemList;
import project.data.LayerTemplate;

class ProjectLayersPanel extends ProjectEditorPanel
{

  public var layers:JQuery;
  public var buttons:JQuery;
  public var layersList:ItemList;
  public var inspector:JQuery;
  public var inspecting:LayerTemplate = null;
  public var layerTemplateEditor:LayerTemplateEditor = null;

  public function new()
  {
    super(2, "layers", "Layers", "layers-solid");
    
    // list of layers on the left side
    layers = $('<div class="project_layers_list">');
    root.append(layers);
      
    // contains new layer button
    buttons = $('<div class="buttons">');
    layers.append(buttons);

    // layers list
    layersList = new ItemList(layers, (a, b, c) -> onReorder(a, b, c));
    
    // inspector
    inspector = $('<div class="project_layers_inspector">');
    root.append(inspector);
  }

  public function begin():Void
  {
    // TODO: This block had an extra set of brackets for some reason. if there are issues, check this section out - austin
    // new layer stuff
    buttons.empty();
    var layerTypes:Dynamic = {};
    for (i in 0...LayerDefinition.definitions.length)
    {
      var def = LayerDefinition.definitions[i];
      layerTypes[def.id] = def.label;
      console.log(def.id + "->" + def.label);
    }
    
    var newLayerType = Fields.createOptions(layerTypes, buttons);
    var newLayerButton = Fields.createButton("plus", null, buttons);
    newLayerButton.on("click", function() { self.newLayer(newLayerType.val()); });

    refreshList();
    if (ogmo.project.layers.length > 0) inspect(ogmo.project.layers[0]);
  }
  
  public function newLayer(definitionId:String):Void
  {
    var definition = LayerDefinition.getDefinitionById(definitionId);

    Popup.openText("Create New Layer", "plus", "new_" + definitionId + "_layer", "Create", "Cancel", function(name)
    {
      if (name != null && name.length > 0)
      {
        var template = definition.createTemplate(ogmo.project);
        template.name = name;
        ogmo.project.layers.push(template);
        refreshList();
        inspect(template);
      }
    });
  }
	
	public function onReorder(node:ItemListNode, into:ItemListNode, below:ItemListNode)
	{
		var layer = node.data;
		var under = (below == null ? null : below.data);
		
		if (layer != null && layer != undefined)
		{
			var n = ogmo.project.layers.indexOf(layer);
			if (n >= 0) ogmo.project.layers.splice(n, 1);
			n = ogmo.project.layers.indexOf(under);
			ogmo.project.layers.splice(n + 1, 0, layer);
		}
		
		refreshList();
	}
    
  public function refreshList():Void
  {
    layersList.empty();
    
    for (i in 0...ogmo.project.layers.length)
    {
      var layer = ogmo.project.layers[i];
      var item = layersList.add(new ItemListItem(layer.name, layer));

      item.setKylesetIcon(layer.definition.icon);
      item.onclick = (current) ->
      {
        self.inspect(current.data);
      }
      item.onrightclick = (current) ->
      {
        var menu = new RightClickMenu(ogmo.mouse);
        menu.onClosed(() -> current.highlighted = false);
        menu.addOption("Delete Layer", "trash", () ->
        {
          Popup.open("Delete Layer", "trash", "Permanently delete <span class='monospace'>" + current.data.name + "</span>?", ["Delete", "Cancel"],(btn) ->
          {
            if (btn == 0)
            {
              var index = ogmo.project.layers.indexOf(current.data);
              if (index >= 0) ogmo.project.layers.splice(index, 1);
              
              refreshList();
              if (inspecting == current.data) inspect(null, false);
            }
          });
        });
        current.highlighted = true;
        menu.open();
      }
    }
  }
  
  public function inspect(layer:LayerTemplate, ?saveOnChange:Bool):Void
  {
    // save current template editor (if it's not null)
    if (saveOnChange == undefined || saveOnChange) save(layerTemplateEditor);
    
    // reselect and clear inspector
    layersList.perform((node) -> node.selected = (node.data == layer));
    inspector.empty();
    
    // load new template editor (if the layer is not null)
    layerTemplateEditor = null;
    if (layer != null)
    {
      inspecting = layer;
      layerTemplateEditor = layer.definition.createTemplateEditor(layer);
      layerTemplateEditor.parentPanel = this;
      layerTemplateEditor.importInto(inspector);
    }
  }
  
  public function save(editor:LayerTemplateEditor):Void
  {
    if (editor != null) editor.save();
  }

  public function end():Void
  {
    save(layerTemplateEditor);
  }
}

// TODO - Figure out a better way to do this window.startupStuff - austin
// Window.startup.push(() -> projectEditor.addPanel(new ProjectLayersPanel()));