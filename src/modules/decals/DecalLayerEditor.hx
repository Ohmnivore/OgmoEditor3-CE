package modules.decals;

import level.editor.LevelSelection;
import level.editor.ui.SidePanel;
import rendering.Texture;
import level.editor.LayerEditor;

class DecalLayerEditor extends LayerEditor
{
	public var brush:Texture;
	public var selection:DecalLayerSelection;
	public var selectedChanged:Bool = true;

	public function new(id:Int)
	{
		super(id);
		selection = new DecalLayerSelection(this);
	}

	public function remove(decal:Decal):Void
	{
		selection.remove(decal);
		(cast layer : DecalLayer).decals.remove(decal);
	}

	override function draw(): Void
	{
		// draw decals
		for (decal in (cast layer : DecalLayer).decals)
		{
			if (decal.texture != null){
				var originInPixels = new Vector(decal.width * decal.origin.x, decal.height * decal.origin.y);
				EDITOR.draw.drawTexture(decal.position.x, decal.position.y, decal.texture, originInPixels, decal.scale, decal.rotation);
			}
			else
			{
				var ox = decal.position.x;
				var oy = decal.position.y;
				var w = decal.width;
				var h = decal.height;
				var originx = decal.origin.x * w;
				var originy = decal.origin.y * h;
				EDITOR.draw.drawRect(ox - originx, oy - originy, w, 1, Color.red);
				EDITOR.draw.drawRect(ox - originx, oy - originy, 1, h, Color.red);
				EDITOR.draw.drawRect(ox + originx - 1, oy - originy, 1, h, Color.red);
				EDITOR.draw.drawRect(ox - originx, oy + originy - 1, w, 1, Color.red);
				EDITOR.draw.drawLine(new Vector(ox - originx, oy - originy), new Vector(ox + originx, oy + originy), Color.red);
				EDITOR.draw.drawLine(new Vector(ox + originx, oy - originy), new Vector(ox - originx, oy + originy), Color.red);
			}
		}

		if (active) for (decal in selection.getHovered()) decal.drawSelectionBox(false);
	}
	
	override function drawOverlay()
	{
		if (selection.getSelected().length <= 0)
			return;
		for (decal in selection.getSelected())
			decal.drawSelectionBox(true);
	}

	override function loop()
	{
		if (!selectedChanged) return;
		selectedChanged = false;
		selectionPanel.refresh();
		EDITOR.dirty();
	}

	override function refresh()
	{
		selection.clear();
		selectedChanged = true;
	}

	override function createPalettePanel():SidePanel
	{
		return new DecalPalettePanel(this);
	}

	override function createSelectionPanel():Null<SidePanel> 
	{
		return new DecalSelectionPanel(this);
	}

	override function afterUndoRedo():Void
	{
		selection.clear();
	}

	override function keyPress(key:Int)
	{
		if (EDITOR.locked)
			return;
		selection.onKeyDown(key);
	}
}


class DecalLayerSelection extends LevelSelection<Decal>
{
	public static var clipboard:Array<Decal> = [];

	public var layerEditor:DecalLayerEditor;

	public function new(layerEditor:DecalLayerEditor)
	{
		super();
		this.layerEditor = layerEditor;
	}

	override private function isEqual(lhs:Decal, rhs:Decal)
	{
		return lhs == rhs;
	}

	override private function getOverlap(rect:Rectangle):Array<Decal>
	{
		var layer:DecalLayer = cast layerEditor.layer;
		return layer.getRect(rect);
	}

	override private function snapToGrid(pos: Vector, into: Vector)
	{
		layerEditor.layer.snapToGrid(pos, into);
	}

	override private function selectedChanged()
	{
		layerEditor.selectedChanged = true;
	}

	override private function move(items:Array<Decal>, delta:Vector, firstChange:Bool)
	{
		if (firstChange)
			EDITOR.level.store("move decals");

		for (decal in items)
			decal.position.add(delta);
	}

	override private function copy(items:Array<Decal>)
	{
		clipboard = [];
		for (decal in items)
			clipboard.push(decal);
	}

	override private function cut(items:Array<Decal>)
	{
		clipboard = [];
		for (decal in items)
			clipboard.push(decal);

		EDITOR.level.store("cut decals");
		for (decal in items.copy())
			layerEditor.remove(decal);
	}

	override private function paste()
	{
		if (clipboard.length == 0)
			return;

		EDITOR.level.store("pasted decals");

		if (!shift())
			selected = [];
		for (decal in clipboard)
		{
			var clone = new Decal(decal.position.clone(), decal.path, decal.texture, decal.origin.clone(), decal.scale.clone(), decal.rotation);
			(cast layerEditor.layer:DecalLayer).decals.push(clone);
			selected.push(clone);
		}
	}

	override private function duplicate(items:Array<Decal>)
	{
		EDITOR.level.store("duplicated decals");

		var newSelection:Array<Decal> = [];
		for (decal in items)
		{
			var clone = new Decal(decal.position.clone().add(new Vector(32, 32)), decal.path, decal.texture, decal.origin.clone(), decal.scale.clone(), decal.rotation);
			(cast layerEditor.layer:DecalLayer).decals.push(clone);
			newSelection.push(clone);
		}
		if (shift())
			selected = selected.concat(newSelection);
		else
			selected = newSelection;
	}

	override private function toggleMassSelect()
	{
		var layer:DecalLayer = cast layerEditor.layer;

		if (selected.length == layer.decals.length)
		{
			selected = [];
		}
		else
		{
			selected = [];
			for (decal in (cast layerEditor.layer:DecalLayer).decals)
				selected.push(decal);
		}
	}

	override private function delete(items:Array<Decal>)
	{
		EDITOR.level.store("delete decals");
		for (decal in items.copy())
			layerEditor.remove(decal);
	}
}
