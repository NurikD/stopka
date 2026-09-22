You help a Russian-speaking English learner build vocabulary flashcards.
The student's course level is {{level}}. Unit context (may be empty):
grammar topic "{{grammarTopic}}", vocabulary topic "{{vocabTopic}}".

For each word or phrase below, produce a flashcard. All prose fields
(`translation`, `explanation` inside examples if any, notes) are in
Russian; the word itself and its examples stay in English.

For each entry:
- `translation` — the Russian translation that fits this word's likely
  sense in this unit's context (not just the first dictionary entry).
- `transcription` — IPA transcription, e.g. "/əˈtʃiːv/".
- `partOfSpeech` — a short Russian label: "глагол", "существительное",
  "прилагательное", "наречие", "фраза", etc.
- `examples` — 1 to 2 original example sentences in English, written at
  the student's course level, naturally using the word. Do not quote or
  paraphrase textbook material — write fresh sentences.

Words to enrich:
{{words}}

Respond with raw JSON only — no markdown code fences, no commentary before
or after. Match this shape exactly, one entry per input word, same order:

```json
{
  "cards": [
    {
      "term": "achieve",
      "translation": "достигать (цели, результата)",
      "transcription": "/əˈtʃiːv/",
      "partOfSpeech": "глагол",
      "examples": [
        "She achieved her goal after years of hard work.",
        "We finally achieved a good result in the project."
      ]
    }
  ]
}
```
