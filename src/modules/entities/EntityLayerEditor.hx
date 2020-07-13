package modules.entities;

import level.editor.Selection;
import level.editor.ui.PropertyDisplay.PropertyDisplayMode;
import level.editor.ui.SidePanel;
import level.editor.LayerEditor;
import rendering.FloatingHTML.FloatingHTMLPropertyDisplay;
import rendering.FloatingHTML.PositionAlignV;
import rendering.FloatingHTML.PositionAlignH;

class EntityLayerEditor extends LayerEditor
{
	public var selection:EntityGroup = new EntityGroup();
	public var hovered:EntityGroup = new EntityGroup();
	public var brush:Int = -1;
	public var entities(get, never):EntityList;
	public var nodeSelection:EntityLayerNodeSelection;

	private var entityTexts = new Map<Int, FloatingHTMLPropertyDisplay>();

	public function new(id:Int)
	{
		super(id);
		brush = 0;
		nodeSelection = new EntityLayerNodeSelection(this);
	}

	override function draw()
	{
		// Draw Hover
		if (active && hovered.amount > 0)
		{
			for (ent in entities.getGroup(hovered)) ent.drawHoveredBox();
		}
		if (active)
		{
			for (node in nodeSelection.getHovered())
			{
				var ent = entities.getByID(node.entityID);
				if (ent != null)
				{
					var nodePos = node.getNodePosition(ent);
					if (nodePos != null)
						ent.drawHoveredNodeBox(nodePos);
				}
			}
		}

		// Draw Entities
		var hasNodes:Array<Entity> = [];
		for (ent in entities.list)
		{
			ent.draw();
			if (!active && ent.canDrawNodes) hasNodes.push(ent);
		}

		// Draw node lines
		if (hasNodes.length > 0) for (ent in hasNodes) ent.drawNodeLines();

		// Draw entity property display texts
		{
			FloatingHTMLPropertyDisplay.visibleFade = EDITOR.level.zoom >= OGMO.settings.propertyDisplay.minimumZoom;
			FloatingHTMLPropertyDisplay.visible = OGMO.settings.propertyDisplay.visible;

			for (ent in entities.list)
			{
				if (!entityTexts.exists(ent.id))
					entityTexts.set(ent.id, new FloatingHTMLPropertyDisplay());
			}

			var toRemove = new Array<Int>();
			for (id => text in entityTexts)
			{
				if (OGMO.settings.propertyDisplay.mode == PropertyDisplayMode.ActiveLayer && !active)
				{
					text.setOpacity(0);
					continue;
				}

				var entity = entities.getByID(id);
				if (entity != null)
				{
					var corners = entity.getCorners(entity.position, 8 / EDITOR.level.zoom);
					var avgX = (corners[0].x + corners[1].x + corners[2].x + corners[3].x) / 4.0;
					var minY = Math.min(Math.min(corners[0].y, corners[1].y), Math.min(corners[2].y, corners[3].y));

					text.setEntity(entity);
					text.setCanvasPosition(new Vector(avgX, minY), PositionAlignH.Left, PositionAlignV.Bottom);
					text.setOpacity(EDITOR.draw.getAlpha());
					text.setFontSize(0.75 * OGMO.settings.propertyDisplay.fontSize);
				}
				else
				{
					text.destroy();
					toRemove.push(id);
				}
			}

			for (id in toRemove)
				entityTexts.remove(id);
		}
	}

	override function drawAbove()
	{
		// Draw Nodes
		for (ent in entities.list) if (ent.canDrawNodes) ent.drawNodeLines();
	}

	override function drawOverlay()
	{
		if (selection.amount <= 0) return;
		for (entity in entities.getGroup(selection)) entity.drawSelectionBox();
	}

	override function loop()
	{
		if (selection.changed)
			nodeSelection.clear();
		else
			return;
		selection.changed = false;
		selectionPanel.refresh();
		EDITOR.dirty();
	}

	override function refresh() {
		selection.clear();
		nodeSelection.clear();
		for (text in entityTexts)
			text.destroy();
		entityTexts.clear();
	}

	override function createPalettePanel():SidePanel return new EntityPalettePanel(this);
	
	override function createSelectionPanel():SidePanel return new EntitySelectionPanel(this);

	override function afterUndoRedo()
	{
		selection.trim(entities);
		nodeSelection.clear();
	}

	public var brushTemplate(get, never):EntityTemplate;
	function get_brushTemplate():EntityTemplate return OGMO.project.getEntityTemplate(brush);

	// region KEYBOARD

	override function keyPress(key:Int)
	{
		if (EDITOR.locked)
			return;

		if (currentTool == 4) // EntityNodeTool
			if (nodeSelection.onKeyDown(key))
				return;

		switch (key)
		{
			case Keys.Backspace, Keys.Delete:
				if (selection.amount <= 0) return;
				EDITOR.level.store('delete entities');
				EDITOR.dirty();
				entities.removeAndClearGroup(selection);
			case Keys.A:
				if (!OGMO.ctrl) return;
				selection.set(entities.list);
				EDITOR.dirty();
			case Keys.D:
				if (!OGMO.ctrl || selection.amount <= 0) return;
				EDITOR.level.store('duplicate entities');
				var copies:Array<Entity> = [ for (e in entities.getGroup(selection)) e.duplicate(layer.downcast(EntityLayer).nextID(), template.gridSize.x * 2, template.gridSize.y * 2) ];
				entities.addList(copies);
				if (OGMO.shift) selection.add(copies);
				else selection.set(copies);
				EDITOR.dirty();
			case Keys.F:
				// Swap selected entities' positions with their first nodes
				if (!OGMO.ctrl || !OGMO.shift || selection.amount <= 0) return;
				var swapped = false;
				for (e in entities.getGroup(selection))
				{
					if (!swapped)
					{
						swapped = true;
						EDITOR.level.store('swap entity and first node positions');
						EDITOR.dirty();
					}
					var temp = e.position;
					e.position = e.nodes[0];
					e.nodes[0] = temp;
				}
			case Keys.H:
				if (OGMO.ctrl || selection.amount <= 0) return;
				EDITOR.level.store("flip entity h");
				for (e in entities.getGroup(selection)) if (e.template.canFlipX) e.flippedX = !e.flippedX;
				selection.changed = true;
				EDITOR.dirty();
			case Keys.V:
				if (OGMO.ctrl || selection.amount <= 0) return;
				EDITOR.level.store("flip entity v");
				for (e in entities.getGroup(selection)) if (e.template.canFlipY) e.flippedY = !e.flippedY;
				selection.changed = true;
				EDITOR.dirty();
		}
	}

	// endregion
	inline function get_entities():EntityList {
		var el:EntityLayer = cast layer;
		return el.entities;
	}

	override  function set_visible(newVisible:Bool):Bool {
		if (!newVisible)
			for (text in entityTexts)
				text.setOpacity(0);
		return super.set_visible(newVisible);
	}
}

class EntityNodeID
{
	public static inline var ROOT_NODE_ID:Int = -1;

	public var entityID:Int;
	public var nodeIdx:Int;

	public function new(entityID:Int, nodeIdx:Int = ROOT_NODE_ID)
	{
		this.entityID = entityID;
		this.nodeIdx = nodeIdx;
	}

	public function getNodePosition(entity:Entity):Vector
	{
		if (nodeIdx == ROOT_NODE_ID)
			return entity.position;
		else if (nodeIdx >= entity.nodes.length)
			return null;
		else
			return entity.nodes[nodeIdx];
	}
}

class EntityLayerNodeSelection extends Selection<EntityNodeID>
{
	public static var clipboard:Array<Vector> = [];

	public var layerEditor:EntityLayerEditor;

	public function new(layerEditor:EntityLayerEditor)
	{
		super();
		this.layerEditor = layerEditor;

		canDragSelect = false;
	}

	public function adjustSelectionIndex(item:EntityNodeID, insert:Bool)
	{
		var increment = insert ? 1 : -1;

		for (sel in selected)
			if (sel.entityID == item.entityID && sel.nodeIdx >= item.nodeIdx)
				sel.nodeIdx += increment;
		for (hov in hovered)
			if (hov.entityID == item.entityID && hov.nodeIdx >= item.nodeIdx)
				hov.nodeIdx += increment;
	}

	override private function isEqual(lhs:EntityNodeID, rhs:EntityNodeID)
	{
		return lhs.entityID == rhs.entityID && lhs.nodeIdx == rhs.nodeIdx;
	}

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

	override private function snapToGrid(pos: Vector, into: Vector)
	{
		layerEditor.layer.snapToGrid(pos, into);
	}

	override private function getOverlap(rect:Rectangle):Array<EntityNodeID>
	{
		var ret = [];

		var entities = layerEditor.entities.getGroupForNodes(layerEditor.selection);
		for (ent in entities)
		{
			if (ent.checkRect(rect))
				ret.push(new EntityNodeID(ent.id, EntityNodeID.ROOT_NODE_ID));

			for (i in 0...ent.nodes.length)
			{
				var nodePos = ent.nodes[i];
				if (ent.checkRect(rect, nodePos))
					ret.push(new EntityNodeID(ent.id, i));
			}
		}

		return ret;
	}

	override private function selectedChanged()
	{
		// Doesn't apply
	}

	override private function move(items:Array<EntityNodeID>, delta:Vector, firstChange:Bool)
	{
		if (firstChange)
			EDITOR.level.store("move nodes");

		for (item in items)
		{
			var ent = layerEditor.entities.getByID(item.entityID);
			if (ent != null)
			{
				var pos = item.getNodePosition(ent);
				pos.add(delta);
			}
		}
	}

	override private function copy(items:Array<EntityNodeID>) // TODO
	{
		clipboard = [];

		var targetId = items[items.length - 1].entityID;
		var target = layerEditor.entities.getByID(targetId);

		for (item in items)
		{
			if (item.entityID == target.id)
			{
				var nodePos = item.getNodePosition(target);
				var newPos = new Vector(nodePos.x, nodePos.y);
				clipboard.push(newPos);
			}
		}
	}

	override private function cut(items:Array<EntityNodeID>)
	{
		copy(items);

		var targetId = items[items.length - 1].entityID;
		var target = layerEditor.entities.getByID(targetId);

		EDITOR.level.store("cut nodes");

		items = items.copy();
		items.sort(sortLargestIdxFirst);

		for (item in items)
		{
			var ent = layerEditor.entities.getByID(item.entityID);
			if (ent != null && ent == target && item.nodeIdx != EntityNodeID.ROOT_NODE_ID)
			{
				remove(item);
				adjustSelectionIndex(item, false);
				ent.nodes.splice(item.nodeIdx, 1);
			}
		}
	}

	override private function paste()
	{
		if (clipboard.length == 0 || selected.length == 0)
			return;

		EDITOR.level.store("paste nodes");

		var lastSelected = selected[selected.length - 1];
		var ent = layerEditor.entities.getByID(lastSelected.entityID);
		if (ent != null)
		{
			for (i in 0...clipboard.length)
			{
				var idx = lastSelected.nodeIdx + 1 + i;
				var vec = clipboard[i].clone();
				ent.nodes.insert(idx, vec);

				var newEntry = new EntityNodeID(ent.id, idx);
				layerEditor.nodeSelection.adjustSelectionIndex(newEntry, true);
				selected.push(newEntry);
			}
		}
	}

	override private function duplicate(items:Array<EntityNodeID>)
	{
		// Doesn't apply
	}

	override private function toggleMassSelect()
	{
		var sumNodes = 0;
		var entities = layerEditor.entities.getGroupForNodes(layerEditor.selection);
		for (ent in entities)
			sumNodes += ent.nodes.length + 1;

		if (selected.length == sumNodes)
		{
			selected = [];
		}
		else
		{
			selected = [];
			for (ent in entities)
			{
				selected.push(new EntityNodeID(ent.id, EntityNodeID.ROOT_NODE_ID));
				for (i in 0...ent.nodes.length)
					selected.push(new EntityNodeID(ent.id, i));
			}
		}
	}

	override private function delete(items:Array<EntityNodeID>)
	{
		EDITOR.level.store("delete nodes");

		items = items.copy();
		items.sort(sortLargestIdxFirst);

		for (item in items)
		{
			var ent = layerEditor.entities.getByID(item.entityID);
			if (ent != null && item.nodeIdx != EntityNodeID.ROOT_NODE_ID)
			{
				remove(item);
				adjustSelectionIndex(item, false);
				ent.nodes.splice(item.nodeIdx, 1);
			}
		}
	}

	// Util

	private function sortLargestIdxFirst(lhs:EntityNodeID, rhs:EntityNodeID):Int
	{
		if (lhs.entityID < rhs.entityID)
		{
			return 1;
		}
		else if (lhs.entityID == rhs.entityID)
		{
			if (lhs.nodeIdx < rhs.nodeIdx)
			{
				return 1;
			}
			else if (lhs.nodeIdx == rhs.nodeIdx)
			{
				return 0;
			}
			else
			{
				return -1;
			}
		}
		else
		{
			return -1;
		}
	}
}
