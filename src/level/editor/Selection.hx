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
	public var selected(get, never):Array<T>;
	private var _selected:Array<T> = [];
	function get_selected():Array<T> return _selected;

	public var hovered(get, never):Array<T>;
	private var _hovered:Array<T> = [];
	function get_hovered():Array<T> return _hovered;

	public var mode(get, never):SelectionMode;
	private var _mode:SelectionMode = NONE;
	function get_mode():SelectionMode return _mode;

	public var selectionChanged = false;

	private var dragStart:Vector = null;
	private var lastPosition:Vector = null;
	private var firstChange:Bool = false;

	private var canDragSelect:Bool = true;

	// Called externally

	public function new()
	{
		
	}

	public function onMouseMove(position:Vector)
	{
		lastPosition = position;

		if (_mode == SelectionMode.SELECT || _mode == SelectionMode.DELETE)
		{
			var rect = getRect();
			if (rect == null)
				rect = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);
			var hit = getOverlap(rect);
			_hovered = hit;

			dirty();
		}
		else if (_mode == SelectionMode.MOVE)
		{
			if (!ctrl())
				snapToGrid(position, position);

			if (!position.equals(dragStart))
			{
				var diff = new Vector(position.x - dragStart.x, position.y - dragStart.y);
				move(_selected, diff, firstChange);
				if (firstChange)
					firstChange = false;
				dragStart = position;

				dirty();
			}
		}
		else if (_mode == SelectionMode.NONE)
		{
			var rect = getRect();
			if (rect == null)
				rect = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);
			var hit = getOverlap(rect);
			var isEqual = hit.length == _hovered.length;
			var i = 0;
			while (isEqual && i < hit.length)
			{
				if (indexOf_internal(_hovered, hit[i]) >= 0)
					isEqual = false;
				i++;
			}
				
			if (!isEqual)
			{
				_hovered = hit;
				dirty();
			}
		}
	}

	public function onMouseDown(position:Vector)
	{
		_hovered = [];

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
				_mode = SelectionMode.SELECT;
		}
		else if (shift())
		{
			toggle(hit);
			if (_selected.length > 0)
				startMove();
			else
				_mode = SelectionMode.NONE;
		}
		else if (containsAny(hit))
		{
			startMove();
		}
		else
		{
			setSelection(hit);
			startMove();
		}
	}

	public function onMouseUp(position:Vector)
	{
		_hovered = [];

		lastPosition = position;

		if (_mode == SelectionMode.SELECT)
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
				toggle(hits);
			else
				setSelection(hits);

			_mode = SelectionMode.NONE;

			overlayDirty();
		}
		else if (_mode == SelectionMode.MOVE)
		{
			_mode = SelectionMode.NONE;
		}
	}

	public function onRightDown(position:Vector)
	{
		lastPosition = position;
		dragStart = lastPosition;
		_mode = SelectionMode.DELETE;
	}

	public function onRightUp(position:Vector)
	{
		lastPosition = position;

		if (_mode == SelectionMode.DELETE)
		{
			var rect = getRect();
			if (rect == null)
				rect = new Rectangle(lastPosition.x, lastPosition.y, 1, 1);

			_mode = SelectionMode.NONE;
			overlayDirty();

			var items = getOverlap(rect);
			if (items.length == 0)
				return;

			delete(items);

			dirty();
			selectionChanged = true;
		}
	}

	public function onKeyDown(key:Int):Bool
	{
		if ((key == Keys.Backspace || key == Keys.Delete) && _selected.length > 0)
		{
			delete(_selected);
			dirty();

			return true;
		}

		if (ctrl())
		{
			if (key == Keys.C && _selected.length > 0)
			{
				copy(_selected);
				dirty();
			}
			else if (key == Keys.X && _selected.length > 0)
			{
				cut(_selected);
				dirty();
			}
			else if (key == Keys.V)
			{
				paste();
				dirty();
			}
			else if (key == Keys.D && _selected.length > 0)
			{
				duplicate(_selected);
				dirty();
			}
			else if (key == Keys.A)
			{
				toggleMassSelect();
				dirty();
			}
			else
				return false;

			return true;
		}

		return false;
	}


	// Util

	public function getRect():Rectangle
	{
		if (_mode == SELECT || _mode == DELETE)
			if (dragStart != null && lastPosition != null && !dragStart.equals(lastPosition))
				return Rectangle.fromPoints(dragStart, lastPosition);
		return null;
	}

	public function remove(item:T)
	{
		var removed = remove_internal(_hovered, item);
		remove_internal(_selected, item);

		if (removed)
		{
			dirty();
			selectionChanged = true;
		}
	}

	public function removeSelection(items:Array<T>)
	{
		var removed = false;

		for (item in items)
			if (remove_internal(_selected, item))
				removed = true;

		if (removed)
		{
			dirty();
			selectionChanged = true;
		}
	}

	public function clear()
	{
		var removed = _selected.length > 0;

		_hovered.resize(0);
		_selected.resize(0);
		dirty();

		if (removed)
			selectionChanged = true;
	}

	public function clearHover()
	{
		_hovered.resize(0);
		dirty();
	}

	public function addSelection(items:Array<T>)
	{
		_selected = _selected.concat(items);

		if (items.length > 0)
		{
			dirty();
			selectionChanged = true;
		}
	}

	public function setSelection(items:Array<T>)
	{
		var same = isSame(_selected, items);
		_selected = items;

		if (!same)
		{
			dirty();
			selectionChanged = true;
		}
	}

	public function toggle(selection:Array<T>):Bool
	{
		var changed = toggle_internal(_selected, selection);

		if (changed)
		{
			dirty();
			selectionChanged = true;
		}

		return changed;
	}

	public function containsAny(list:Array<T>):Bool
	{
		return containsAny_internal(_selected, list);
	}


	// Internal

	private function startMove()
	{
		_mode = SelectionMode.MOVE;
		firstChange = true;
		if (!ctrl())
			snapToGrid(dragStart, dragStart);
	}

	private function toggle_internal(group:Array<T>, selection:Array<T>):Bool
	{
		var changed = false;

		var removing:Array<T> = [];
		for (item in selection)
		{
			if (indexOf_internal(group, item) >= 0)
			{
				removing.push(item);
				changed = true;
			}
			else
			{
				group.push(item);
				changed = true;
			}
		}
		for (item in removing)
			remove_internal(group, item);

		return changed;
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

	private function isSame(oldList:Array<T>, newList:Array<T>):Bool
	{
		if (oldList.length != newList.length)
			return false;

		var same = true;
		for (i in 0...oldList.length)
		{
			if (!isEqual(oldList[i], newList[i]))
			{
				same = false;
				break;
			}
		}

		return same;
	}


	// User-implemented

	private function isEqual(lhs:T, rhs:T) { return false; }

	private function ctrl():Bool { return false; }

	private function shift():Bool { return false; }

	private function dirty() {}

	private function overlayDirty() {}

	private function snapToGrid(pos: Vector, into: Vector) {}

	private function getOverlap(rect:Rectangle):Array<T> { return []; }

	private function move(items:Array<T>, delta:Vector, firstChange:Bool) {}

	private function copy(items:Array<T>) {}

	private function cut(items:Array<T>) {}

	private function paste() {}

	private function duplicate(items:Array<T>) {}

	private function toggleMassSelect() {}

	private function delete(items:Array<T>) {}
}
