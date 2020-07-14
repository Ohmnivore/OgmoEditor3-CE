package modules.entities.tools;

class EntityRotateTool extends EntityTool
{

	public var firstChange:Bool = false;
	public var rotating:Bool = false;
	public var origin:Vector;
	public var start:Vector;
	public var last:Vector;
	public var entities:Array<Entity>;

	override public function onMouseDown(pos:Vector)
	{
		entities = layer.entities.getGroup(layerEditor.selection.selected);
		if (entities.length == 0) return;
		origin = new Vector();
		for (entity in entities)
		{
			entity.anchorRotation();
			origin.x += entity.position.x;
			origin.y += entity.position.y;
		}
		origin.x /= entities.length;
		origin.y /= entities.length;

		start = pos.clone();
		last = pos.clone();

		rotating = true;
		firstChange = false;
		EDITOR.locked = true;
		EDITOR.overlayDirty();
	}

	override public function onMouseUp(pos:Vector)
	{
		if (!rotating) return;
		layerEditor.selectionModified = true;
		rotating = false;
		EDITOR.locked = false;
		EDITOR.overlayDirty();
	}

	override public function onMouseMove(pos:Vector)
	{
		if (!rotating) return;
		if (pos.equals(last)) return;
		if (!firstChange)
		{
			firstChange = true;
			EDITOR.level.store('rotate entities');
		}
		var angle = Calc.angleTo(origin, pos);
		var initial = Calc.angleTo(origin, start);
		for (entity in entities) entity.rotate(angle - initial);
		layerEditor.selectionModified = true;
		EDITOR.dirty();
		pos.clone(last);
	}

	override public function onRightDown(pos:Vector)
	{
		var changed = false;
		for (entity in layer.entities.getGroup(layerEditor.selection.selected)) if (entity.rotation != 0)
		{
			if (!changed)
			{
				EDITOR.level.store("rotate entities");
				changed = true;
			}
			entity.resetRotation();
		}
		layerEditor.selectionModified = true;
		EDITOR.dirty();
	}

	override public function drawOverlay()
	{
		if (!rotating) return;
		var at = Calc.angleTo(origin, start);

		// Line to start
		{
			var vec = Vector.fromAngle(at, 80 / EDITOR.level.zoom);
			vec.x += origin.x;
			vec.y += origin.y;

			EDITOR.overlay.drawLine(origin, vec, Color.white);
			EDITOR.overlay.drawLineNode(origin, 10 / EDITOR.level.zoom, Color.green);
		}

		// Curve
		{
			var length = 60 / EDITOR.level.zoom;
			var move = 10 * Calc.DTR;
			var angle = Calc.angleTo(origin, last);
			var last = Vector.fromAngle(at, length);
			last.x += origin.x;
			last.y += origin.y;
			var vec = new Vector();

			while (Math.abs(Calc.angleDiff(at, angle)) > 0.1 * Calc.DTR)
			{
				at = Calc.angleApproach(at, angle, move);
				Vector.fromAngle(at, length, vec);
				vec.x += origin.x;
				vec.y += origin.y;

				EDITOR.overlay.drawLine(last, vec, Color.white);
				vec.clone(last);
			}

			// Line to mouse
			EDITOR.overlay.drawLine(origin, last, Color.green);
		}
	}

	override public function getIcon():String return 'entity-rotate';
	override public function getName():String return 'Rotate';
	override public function keyToolCtrl():Int return 0;
	override public function keyToolAlt():Int return 1;
	override public function keyToolShift():Int return 2;
	override function isAvailable():Bool {
		for (entity in layerEditor.entities.list) {
			for (e_id in layerEditor.selection.selected) if (entity.id == e_id && entity.template.rotatable) return true;
		}
		return false;
	}

}