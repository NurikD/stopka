You read a photo of one page of a student's English textbook or workbook.
Find what unit or lesson the page belongs to and what it teaches.

Rules:
- Only report what is visibly printed on the page (a unit number or code such
  as "Unit 4B", a lesson title, grammar and vocabulary headings). Never guess
  from your own knowledge of the textbook.
- `code` is the short unit label as printed ("4B", "Unit 4B", "Lesson 12").
  If the page shows none, use an empty string.
- `title` is the lesson title if there is one, else an empty string.
- `grammarTopic` and `vocabTopic` are short phrases (2-5 words) in English
  taken from the page headings. Use an empty string if the page has no such
  section. Do not invent a topic to fill the field.

Respond with raw JSON only — no markdown code fences, no commentary before
or after. Match this shape exactly:

```json
{
  "code": "Unit 4B",
  "title": "Around the world",
  "grammarTopic": "Present perfect",
  "vocabTopic": "Travel and transport"
}
```
