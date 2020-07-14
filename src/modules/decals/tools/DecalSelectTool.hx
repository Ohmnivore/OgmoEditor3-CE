package modules.decals.tools;

import level.editor.Selection.SelectionMode;

class DecalSelectTool extends DecalTool
{
	override public function drawOverlay()
	{
		var rect = layerEditor.selection.getRect();
		var mode = layerEditor.selection.mode;
		
		if (rect != null)
		{
			if (mode == SelectionMode.SELECT)
				EDITOR.overlay.drawRect(rect.left, rect.top, rect.width, rect.height, Color.green.x(0.2));
			else if (mode == SelectionMode.DELETE)
				EDITOR.overlay.drawRect(rect.left, rect.top, rect.width, rect.height, Color.red.x(0.2));
		}
	}

	override public function deactivated()
	{
		layerEditor.selection.clearHover();
	}

	override public function onKeyPress(key:Int)
	{
		if (OGMO.ctrl)
			return;

		var selected = layerEditor.selection.selected;
		if (selected.length == 0)
			return;

		if (key == Keys.H)
		{
			if ((cast layerEditor.template : DecalLayerTemplate).scaleable)
			{
				EDITOR.level.store("flip decal h");
				for (decal in selected)
					decal.scale.x = -decal.scale.x;
				layerEditor.selectionModified = true;
				EDITOR.dirty();
			}
		}
		else if (key == Keys.V)
		{
			if ((cast layerEditor.template : DecalLayerTemplate).scaleable)
			{
				EDITOR.level.store("flip decal v");
				for (decal in selected)
					decal.scale.y = -decal.scale.y;
				layerEditor.selectionModified = true;
				EDITOR.dirty();
			}
		}
		else if (key == Keys.B)
		{
			EDITOR.level.store("move decal back");
			for (decal in selected) OGMO.shift ? moveDecalToBack(decal) : moveDecalBack(decal);
			EDITOR.dirty();
		}
		else if (key == Keys.F)
		{
			EDITOR.level.store("move decal forward");
			for (decal in selected) OGMO.shift ? moveDecalToFront(decal) : moveDecalForward(decal);
			EDITOR.dirty();
		}
	}

	function moveDecalBack(decal:Decal)
	{
		var index = layer.decals.indexOf(decal);
		if (index < 0) return;
		var target = 0.max(index - 1).int();
		layer.decals.splice(index, 1);
		layer.decals.insert(target, decal);
	}

	function moveDecalForward(decal:Decal)
	{
		var index = layer.decals.indexOf(decal);
		if (index < 0) return;
		var target = (layer.decals.length - 1).min(index + 1).int();
		layer.decals.splice(index, 1);
		layer.decals.insert(target, decal);
	}

	function moveDecalToBack(decal:Decal)
	{
		var index = layer.decals.indexOf(decal);
		if (index < 0) return;
		layer.decals.splice(index, 1);
		layer.decals.unshift(decal);
	}

	function moveDecalToFront(decal:Decal)
	{
		var index = layer.decals.indexOf(decal);
		if (index < 0) return;
		layer.decals.splice(index, 1);
		layer.decals.push(decal);
	}

	override public function onMouseDown(pos:Vector)
	{
		layerEditor.selection.onMouseDown(pos);
	}

	override public function onMouseUp(pos:Vector)
	{
		layerEditor.selection.onMouseUp(pos);
	}

	override public function onMouseMove(pos:Vector)
	{
		layerEditor.selection.onMouseMove(pos);
	}

	override public function onRightDown(pos:Vector)
	{
		layerEditor.selection.onRightDown(pos);
	}

	override public function onRightUp(pos:Vector)
	{
		layerEditor.selection.onRightUp(pos);
	}

	override public function getIcon():String return "entity-selection";
	override public function getName():String return "Select";
	override public function keyToolAlt():Int return 1;

}