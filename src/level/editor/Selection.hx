package level.editor;

enum SelectionMode
{
	NONE;
	SELECT;
	DELETE;
	MOVE;
}

class Selection<T>
{
	private var selected:Array<T> = [];
	private var hovered:Array<T> = [];
	private var dragStart:Vector = null;
	private var lastPosition:Vector = null;
	private var mode:SelectionMode = NONE;
	private var firstChange:Bool = false;

	private var canDragSelect:Bool = true;

	// Called externally

	public function new()
	{
		
	}

	public function onMouseMove(position:Vector)
	{
		lastPosition = position;

		if (mode == SelectionMode.SELECT || mode == SelectionMode.DELETE)
		{
			var rect = getRect();
			if (rect == null)
				rect = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);
			var hit = getOverlap(rect);
			hovered = hit;

			dirty();
			selectedChanged();
		}
		else if (mode == SelectionMode.MOVE)
		{
			if (!ctrl())
				snapToGrid(position, position);

			if (!position.equals(dragStart))
			{
				var diff = new Vector(position.x - dragStart.x, position.y - dragStart.y);
				move(selected, diff, firstChange);
				if (firstChange)
					firstChange = false;
				dragStart = position;

				dirty();
				selectedChanged();
			}
		}
		else if (mode == SelectionMode.NONE)
		{
			var rect = getRect();
			if (rect == null)
				rect = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);
			var hit = getOverlap(rect);
			var isEqual = hit.length == hovered.length;
			var i = 0;
			while (isEqual && i < hit.length)
			{
				if (indexOf_internal(hovered, hit[i]) >= 0)
					isEqual = false;
				i++;
			}
				
			if (!isEqual)
			{
				hovered = hit;
				dirty();
				selectedChanged();
			}
		}
	}

	public function onMouseDown(position:Vector)
	{
		hovered = [];

		lastPosition = position;
		dragStart = lastPosition;

		var rect = getRect();
		if (rect == null)
			rect = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);
		var hit = getOverlap(rect);
		if (hit.length > 0)
			hit.resize(1);

		if (hit.length == 0)
		{
			if (canDragSelect)
				mode = SelectionMode.SELECT;
		}
		else if (shift())
		{
			toggleSelection(hit);
			if (selected.length > 0)
				startMove();
			else
				mode = SelectionMode.NONE;
		}
		else if (containsAny(hit))
		{
			startMove();
		}
		else
		{
			selected = hit;
			startMove();
		}

		dirty();
		selectedChanged();
	}

	public function onMouseUp(position:Vector)
	{
		hovered = [];

		lastPosition = position;

		if (mode == SelectionMode.SELECT)
		{
			var rect = getRect();
			if (rect == null)
				rect = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);

			var hits:Array<T>;
			if (dragStart.equals(lastPosition))
			{
				hits = getOverlap(rect);
				if (hits.length > 0)
					hits.resize(1);
			}
			else
			{
				hits = getOverlap(rect);
			}

			if (shift())
				toggleSelection(hits);
			else
				selected = hits;

			mode = SelectionMode.NONE;

			overlayDirty();
			selectedChanged();
		}
		else if (mode == SelectionMode.MOVE)
		{
			mode = SelectionMode.NONE;
		}
	}

	public function onRightDown(position:Vector)
	{
		lastPosition = position;
		dragStart = lastPosition;
		mode = SelectionMode.DELETE;
	}

	public function onRightUp(position:Vector)
	{
		lastPosition = position;

		if (mode == SelectionMode.DELETE)
		{
			var rect = getRect();
			if (rect == null)
				rect = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);

			mode = SelectionMode.NONE;
			overlayDirty();

			var items = getOverlap(rect);
			if (items.length == 0)
				return;

			delete(items);

			dirty();
			selectedChanged();
		}
	}

	public function onKeyDown(key:Int):Bool
	{
		if ((key == Keys.Backspace || key == Keys.Delete) && selected.length > 0)
		{
			delete(selected);
			dirty();
			selectedChanged();

			return true;
		}

		if (ctrl())
		{
			if (key == Keys.C && selected.length > 0)
			{
				copy(selected);
			}
			else if (key == Keys.X && selected.length > 0)
			{
				cut(selected);
				dirty();
				selectedChanged();
			}
			else if (key == Keys.V)
			{
				paste();
				dirty();
				selectedChanged();
			}
			else if (key == Keys.D && selected.length > 0)
			{
				duplicate(selected);
				dirty();
				selectedChanged();
			}
			else if (key == Keys.A)
			{
				toggleMassSelect();
				dirty();
				selectedChanged();
			}
			else
			{
				return false;
			}

			return true;
		}

		return false;
	}


	// Util

	public function getSelected():Array<T>
	{
		return selected;
	}

	public function getHovered():Array<T>
	{
		return hovered;
	}

	public function getMode():SelectionMode
	{
		return mode;
	}

	public function getRect():Rectangle
	{
		if (mode == SELECT || mode == DELETE)
			if (dragStart != null && lastPosition != null && !dragStart.equals(lastPosition))
				return Rectangle.fromPoints(dragStart, lastPosition);
		return null;
	}

	public function remove(item:T)
	{
		remove_internal(hovered, item);
		remove_internal(selected, item);
	}

	public function clear()
	{
		hovered.resize(0);
		selected.resize(0);
	}

	public function clearHover()
	{
		hovered.resize(0);
	}

	public function addSelected(item:T)
	{
		selected.push(item);
		dirty();
		selectedChanged();
	}

	public function addSelection(items:Array<T>)
	{
		selected = selected.concat(items);
		dirty();
		selectedChanged();
	}

	public function toggleSelection(selection:Array<T>)
	{
		return toggleSelection_internal(selected, selection);
	}

	public function containsAny(list:Array<T>):Bool
	{
		return containsAny_internal(selected, list);
	}


	// Internal

	private function startMove()
	{
		mode = SelectionMode.MOVE;
		firstChange = true;
		if (!ctrl())
			snapToGrid(dragStart, dragStart);
	}

	private function toggleSelection_internal(group:Array<T>, selection:Array<T>)
	{
		var removing:Array<T> = [];
		for (item in selection)
		{
			if (indexOf_internal(group, item) >= 0)
				removing.push(item);
			else
				group.push(item);
		}
		for (item in removing)
			remove_internal(group, item);
	}

	private function containsAny_internal(group:Array<T>, list:Array<T>):Bool
	{
		for (item in list)
			if (indexOf_internal(group, item) >= 0)
				return true;
		return false;
	}

	private function indexOf_internal(list:Array<T>, item:T):Int
	{
		for (i in 0...list.length)
			if (isEqual(item, list[i]))
				return i;
		return -1;
	}

	private function remove_internal(list:Array<T>, item:T):Bool
	{
		for (i in 0...list.length)
			if (isEqual(item, list[i]))
			{
				list.splice(i, 1);
				return true;
			}
		return false;
	}


	// User-implemented

	private function isEqual(lhs:T, rhs:T)
	{
		return false;
	}

	private function ctrl():Bool
	{
		return false;
	}

	private function shift():Bool
	{
		return false;
	}

	private function dirty()
	{
		
	}

	private function overlayDirty()
	{
		
	}

	private function snapToGrid(pos: Vector, into: Vector)
	{

	}

	private function getOverlap(rect:Rectangle):Array<T>
	{
		return [];
	}

	private function selectedChanged()
	{
		
	}

	private function move(items:Array<T>, delta:Vector, firstChange:Bool)
	{
		
	}

	private function copy(items:Array<T>)
	{
		
	}

	private function cut(items:Array<T>)
	{
		
	}

	private function paste()
	{
		
	}

	private function duplicate(items:Array<T>)
	{
		
	}

	private function toggleMassSelect()
	{
		
	}

	private function delete(items:Array<T>)
	{
		
	}
}
