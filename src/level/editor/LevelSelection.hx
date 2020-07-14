package level.editor;

import level.data.Layer;

class LevelSelection<T> extends Selection<T>
{
	override private function ctrl():Bool
	{
		return OGMO.ctrl;
	}

	override private function shift():Bool
	{
		return OGMO.shift;
	}

	override private function dirty()
	{
		EDITOR.dirty();
	}

	override private function overlayDirty()
	{
		EDITOR.overlayDirty();
	}
}
