const std = @import("std");
const ztg = @import("ztg");
const b2 = @import("box2d");

pub fn include(comptime wb: *ztg.WorldBuilder) void {
    wb.addComponents(&.{b2.b2BodyId});
    wb.addResource(b2.b2WorldId, undefined);
    wb.addSystems(.{ .post_update = postUpdate });
    wb.addOnRemoveForComponent(b2.b2BodyId, bodyIdOnRemoved);
}

fn postUpdate(q: ztg.Query(.{ b2.b2BodyId, ztg.base.Transform })) void {
    for (q.items(b2.b2BodyId), q.items(ztg.base.Transform)) |id, tr| {
        const pos = b2.b2Body_GetPosition(id.*);
        tr.setPos(.fromVec2(pos, 0));
    }
}

fn bodyIdOnRemoved(body_id: b2.b2BodyId) void {
    b2.b2DestroyBody(body_id);
}

pub fn createBox(b2world: b2.b2WorldId, options: struct {
    half_extents: ztg.Vec2,
    body_def: *const b2.b2BodyDef,
    shape_def: *const b2.b2ShapeDef,
}) b2.b2BodyId {
    const body_id = b2.b2CreateBody(b2world, options.body_def);
    const dynamicBox = b2.b2MakeBox(options.half_extents.x, options.half_extents.y);
    _ = b2.b2CreatePolygonShape(body_id, options.shape_def, &dynamicBox);
    return body_id;
}
