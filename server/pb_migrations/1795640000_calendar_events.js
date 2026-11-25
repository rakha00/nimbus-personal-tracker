/// <reference path="../pb_data/types.d.ts" />

// Calendar: one-off or yearly events, each with at most one reminder (scheduled on the phone).
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const OWN = "owner = @request.auth.id";
  const c = new Collection({
    type: "base", name: "calendar_events",
    listRule: OWN, viewRule: OWN, deleteRule: OWN,
    createRule: '@request.auth.id != "" && @request.body.owner = @request.auth.id',
    updateRule: OWN + " && (@request.body.owner:isset = false || @request.body.owner = @request.auth.id)",
    fields: [
      { name: "owner", type: "relation", collectionId: users.id, required: true, maxSelect: 1, cascadeDelete: true },
      { name: "title", type: "text", required: true, max: 200 },
      { name: "starts_at", type: "date", required: true },
      { name: "all_day", type: "bool" },
      { name: "yearly", type: "bool" },
      { name: "reminder", type: "select", maxSelect: 1, values: ["at_start", "10m", "1h", "1d"] }, // empty = none
      { name: "note", type: "text", max: 5000 },
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
    ],
    indexes: ["CREATE INDEX idx_calendar_owner_starts ON calendar_events (owner, starts_at)"],
  });
  app.save(c);
}, (app) => {
  app.delete(app.findCollectionByNameOrId("calendar_events"));
});
