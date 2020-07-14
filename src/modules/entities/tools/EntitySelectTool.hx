package modules.entities.tools;

import level.editor.Selection.SelectionMode;
import modules.entities.tools.EntityTool;

class EntitySelectTool extends EntityTool
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

	override public function getIcon():String return 'entity-selection';
	override public function getName():String return 'Select';
	override public function keyToolAlt():Int return 1;
}
