/// <reference path="../pb_data/types.d.ts" />

// One assistant mode: "auto" lets the model decide between drafting records and answering.
// "record" and "ask" stay valid for the requests already saved.
migrate((app) => {
  const c = app.findCollectionByNameOrId("ai_requests");
  c.fields.getByName("mode").values = ["record", "ask", "auto"];
  app.save(c);
}, (app) => {
  const c = app.findCollectionByNameOrId("ai_requests");
  c.fields.getByName("mode").values = ["record", "ask"];
  app.save(c);
});
