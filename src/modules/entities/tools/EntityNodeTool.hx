package modules.entities.tools;

import level.editor.Selection.SelectionMode;
import modules.entities.EntityLayerEditor.EntityNodeID;

class LineProjectionData
{
	public static inline var MAX_DISTANCE:Float = 6.0;

	public var distance:Float;
	public var projection:Vector;
	public var entityID:Int;
	public var nodeIdx:Int;

	public function new(distance:Float, projection:Vector, entityID:Int, nodeIdx:Int)
	{
		this.distance = distance;
		this.projection = projection;
		this.entityID = entityID;
		this.nodeIdx = nodeIdx;
	}

	public function active():Bool
	{
		return distance <= MAX_DISTANCE;
	}
}

class EntityNodeTool extends EntityTool
{
	private var closestProjection:LineProjectionData = null;
	private var lastClosestProjection:LineProjectionData = null;

	override public function deactivated()
	{
		layerEditor.nodeSelection.clearHover();
	}

	override function drawOverlay()
	{
		var rect = layerEditor.nodeSelection.getRect();
		var mode = layerEditor.nodeSelection.mode;
		
		if (rect != null)
		{
			if (mode == SelectionMode.SELECT)
				EDITOR.overlay.drawRect(rect.left, rect.top, rect.width, rect.height, Color.green.x(0.2));
			else if (mode == SelectionMode.DELETE)
				EDITOR.overlay.drawRect(rect.left, rect.top, rect.width, rect.height, Color.red.x(0.2));
		}

		if (closestProjection != null && closestProjection.active())
		{
			var x = closestProjection.projection.x;
			var y = closestProjection.projection.y;
			var size = 8.0;
			EDITOR.overlay.drawRect(x - size / 2.0, y - size / 2.0, size, size, Color.green.x(0.5));
		}

		for (node in layerEditor.nodeSelection.selected)
		{
			var ent = layer.entities.getByID(node.entityID);
			if (ent != null)
			{
				var pos = node.getNodePosition(ent);
				if (pos != null)
					ent.drawNodeSelectionBox(pos);
			}
		}
	}

	override public function onMouseMove(pos:Vector)
	{
		var hovering = layerEditor.nodeSelection.hovered.length > 0;

		layerEditor.nodeSelection.onMouseMove(pos);

		closestProjection = null;

		if (!hovering && layerEditor.nodeSelection.mode == SelectionMode.NONE)
		{
			var processProjection = function(projection:Vector, entityID:Int, nodeIdx:Int)
			{
				var distance = Vector.dist(pos, projection);
				if (closestProjection == null || distance <= closestProjection.distance)
					closestProjection = new LineProjectionData(distance, projection, entityID, nodeIdx);
			};

			var entities = layer.entities.getGroupForNodes(layerEditor.selection.selected);
			for (ent in entities)
			{
				if (!ent.canAddNode)
					continue;

				var display = ent.template.nodeDisplay;
				if (display == NodeDisplayModes.PATH || display == NodeDisplayModes.CIRCUIT)
				{
					var prev:Vector = ent.position;
					for (i in 0...ent.nodes.length)
					{
						var node = ent.nodes[i];
						var projection = getPointToSegmentProjection(pos, prev, node);
						if (projection != null)
							processProjection(projection, ent.id, i);
						prev = node;
					}
					if (display == NodeDisplayModes.CIRCUIT && ent.nodes.length > 1)
					{
						var projection = getPointToSegmentProjection(pos, prev, ent.position);
						if (projection != null)
							processProjection(projection, ent.id, ent.nodes.length);
					}
				}
			}

			if ((closestProjection != null && closestProjection.active()) ||
				(lastClosestProjection != closestProjection)) // shallow compare for nulls, actual contents don't matter
			{
				lastClosestProjection = closestProjection;
				EDITOR.overlayDirty();
			}
		}
	}

	override public function onMouseDown(pos:Vector)
	{
		var hovering = layerEditor.nodeSelection.hovered.length > 0;

		layerEditor.nodeSelection.onMouseDown(pos);

		if (!hovering && layerEditor.nodeSelection.mode == SelectionMode.NONE)
		{
			EDITOR.locked = true;
			EDITOR.level.store("add node(s)");

			if (!OGMO.ctrl) layer.snapToGrid(pos, pos);
			if (!OGMO.shift) layerEditor.nodeSelection.clear();

			var entities = layer.entities.getGroupForNodes(layerEditor.selection.selected);
			for (e in entities)
			{
				if (e.canAddNode)
				{
					if (closestProjection != null && closestProjection.active() && e.id == closestProjection.entityID)
					{
						var n = closestProjection.projection.clone();
						if (!OGMO.ctrl) layer.snapToGrid(n, n);
						e.nodes.insert(closestProjection.nodeIdx, n);

						var newEntry = new EntityNodeID(e.id, closestProjection.nodeIdx);
						layerEditor.nodeSelection.adjustSelectionIndex(newEntry, true);
						if (OGMO.shift)
							layerEditor.nodeSelection.addSelection([newEntry]);
						else
							layerEditor.nodeSelection.setSelection([newEntry]);
					}
					else
					{
						e.addNodeAt(pos);
						var newEntry = new EntityNodeID(e.id, e.nodes.length - 1);
						if (OGMO.shift)
							layerEditor.nodeSelection.addSelection([newEntry]);
						else
							layerEditor.nodeSelection.setSelection([newEntry]);
					}
				}
			}
		}
	}

	override public function onMouseUp(pos:Vector)
	{
		layerEditor.nodeSelection.onMouseUp(pos);
		EDITOR.locked = false;
	}

	override public function onRightDown(pos:Vector)
	{
		layerEditor.nodeSelection.onRightDown(pos);
	}

	override public function onRightUp(pos:Vector)
	{
		layerEditor.nodeSelection.onRightUp(pos);
	}

	override public function getIcon():String return "entity-nodes";
	override public function getName():String return "Add Node";
	override public function keyToolAlt():Int return 1;
	override function isAvailable():Bool {
		for (entity in layerEditor.entities.list) {
			for (e_id in layerEditor.selection.selected) if (entity.id == e_id && entity.template.hasNodes) return true;
		}
		return false;
	}

	private function getPointToSegmentProjection(point:Vector, start:Vector, end:Vector):Vector
	{
		var segmentDir = new Vector(end.x - start.x, end.y - start.y);
		var segmentLength = segmentDir.length;

		if (segmentLength < 0.01)
			return null;

		segmentDir.x /= segmentLength;
		segmentDir.y /= segmentLength;

		var localPoint = new Vector(point.x - start.x, point.y - start.y);

		var dotProduct = Vector.dot(localPoint, segmentDir);
		if (dotProduct < 0 || dotProduct > segmentLength)
			return null;

		var projection = new Vector(segmentDir.x * dotProduct + start.x, segmentDir.y * dotProduct + start.y);
		return projection;
	}
}