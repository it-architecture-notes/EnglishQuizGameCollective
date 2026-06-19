# Non-Image Question Quality Audit (2026-06-09)

Second-pass audit. Reviewed all 69 `questions.json` files under `app/assets/quiz-data/levels/implemented/`, skipping all `imageQuizTemplate-*` questions.

This report keeps only high-confidence improvement items: ambiguous correct answers, distractors that can also be correct, obviously irrelevant/invalid distractors, grammar errors, malformed data, or clear level-theme mismatches.

## Flagged Questions

### `grocery-shopping`
- **Q5 / WordPairs**  
  **Current:** `heavy`, `light`, `empty`, `full`  
  **Issue:** `light` translations appear to use the noun sense (`light` as illumination) instead of the adjective sense (`not heavy`).  
  **Suggestion:** Keep `light`, but update translations to mean lightweight/not heavy.  
  **Suggested alternates:** `small`, `thin`, `soft`
- **Q15 / ConvoTemplate-1**  
  **Current:** `Hello. Did you ____ everything?` | answer `find`  
  **Weak choices:** `buy`, `get`  
  **Issue:** `Did you buy/get everything?` is also valid in a grocery context.  
  **Suggested distractors:** `carry`, `open`, `drop`

### `at-the-train-station`
- **Q6 / DialogueCompletion**  
  **Current:** `Why do you run?` | answer `We run to catch the train.`  
  **Weak choice:** `We run to the station`  
  **Issue:** It can answer the purpose question.  
  **Suggestion:** `Why are you running to the platform?`  
  **Suggested distractors:** `We run to clean the train.`, `We run to read the ticket.`, `We run to open the suitcase.`
- **Q14 / ClozeSequence**  
  **Current:** `____ trains _____ at the station at noon.` | answer `both`, `arrive`  
  **Weak choice:** `depart`  
  **Issue:** `Both trains depart at the station at noon` is also plausible.  
  **Suggested distractors:** `arrives`, `arriving`, `arrival`

### `city-walk`
- **Q2 / ConvoTemplate-1**  
  **Current:** `Do you want to _____ to the park?` | answer `walk`  
  **Weak choice:** `come`  
  **Issue:** `Do you want to come to the park?` is valid.  
  **Suggested distractors:** `sit`, `look`, `sleep`
- **Q15 / ClozeSequence**  
  **Current:** `I am _____ so I will go _____` | answer `tired`, `back`  
  **Weak choice:** `hungry`  
  **Issue:** `I am hungry so I will go back` is plausible.  
  **Suggestion:** `My legs hurt, so I will go _____.` | answer `back`  
  **Suggested distractors:** `forward`, `inside`, `around`

### `bathroom`
- **Q9 / ClozeSequence**  
  **Current:** `She ____ her hands to maintain good _____.` | answer `washes`, `hygiene`  
  **Weak choice:** `health`  
  **Issue:** `maintain good health` is a valid phrase.  
  **Suggested distractors:** `mirror`, `towel`, `shower`
- **Q12 / DialogueCompletion**  
  **Current:** `I’m going to take a shower.` | answer `Okay, don’t forget your towel.`  
  **Weak choice:** `Bursh your teeth carefully`  
  **Issue:** Typo/grammar error.  
  **Suggested distractors:** `Brush your hair carefully.`, `The mirror is dirty.`, `I need a clean towel.`

### `living-room`
- **Q2 / ConvoTemplate-1**  
  **Current:** `Where do you ____? / I ____ on the sofa.` | answer `sit`  
  **Weak choice:** `lie`  
  **Issue:** `I lie on the sofa` can also be correct.  
  **Suggested distractors:** `cook`, `wash`, `drive`
- **Q5 / WordPairs**  
  **Current:** `softer`, `softest`, `more comfortable`, `the most comfortable`  
  **Issue:** Some translations make comparative/superlative choices ambiguous, e.g. Spanish can map both `softer` and `softest` to `más suave`.  
  **Suggestion:** Make superlatives explicit (`the softest`) and update translations accordingly.  
  **Suggested set:** `soft`, `softer`, `the softest`
- **Q6 / DialogueCompletion**  
  **Current:** `Who else is in the living room?` | answer `My brother.`  
  **Weak choices:** `10 o'clock`, `My father else`, `Every person`  
  **Issue:** Distractors are nonsensical or ungrammatical; the question is also open-ended.  
  **Suggestion:** `Where is your brother?` | answer `He is in the living room.`  
  **Suggested distractors:** `He is in the kitchen.`, `He is in the bedroom.`, `He is in the garden.`
- **Q9 / ClozeSequence**  
  **Current:** `Their living room is ____` | answer `small but bright`  
  **Issue:** Without context, several room descriptions could be correct.  
  **Suggestion:** `Their living room is not big, but it has a lot of light. It is ____.`  
  **Suggested distractors:** `large and dark`, `small but noisy`, `cold and empty`

### `greetings`
- **Q4 / ConvoTemplate-1**  
  **Current:** `How are you? / _____ , and you?` | answer `I am fine`  
  **Weak choice:** `I am good`  
  **Issue:** Also a correct response.  
  **Suggested distractors:** `I am Beth`, `Good night`, `See you later`
- **Q6 / DialogueCompletion**  
  **Current:** `How old are you?` | answer `I am 10 years old.`  
  **Weak choice:** `I was born 10 years ago.`  
  **Issue:** Semantically equivalent.  
  **Suggested distractors:** `I am in school.`, `I have ten books.`, `I am from Spain.`

### `waking-up`
- **Q3 / ClozeSequence**  
  **Current:** `Time to _____ ! You’ll _____ the bus.` | answer `get up`, `miss`  
  **Weak choice:** `go`  
  **Issue:** `Time to go! You’ll miss the bus` is valid.  
  **Suggested distractors:** `sit down`, `look out`, `turn off`
- **Q11 / WordPairs**  
  **Current:** `and`, `of the girl`, `to the school`, `from the house`  
  **Issue:** Clear level-theme mismatch for a waking-up level.  
  **Suggestion:** Replace with waking routine terms.  
  **Suggested set:** `wake up`, `get up`, `early`, `late`

### `at-the-post-office`
- **Q7 / AppearDisappear**  
  **Current:** `It is important that you bring a valid ID.`  
  **Weak choice:** `nurse`  
  **Issue:** Obvious post-office theme mismatch.  
  **Suggested distractors:** `form`, `stamp`, `receipt`
- **Q15 / ClozeSequence**  
  **Current:** `______ does it _____ to send a package to New York?` | answer `how much`, `cost`  
  **Weak choices:** `how long`, `take`  
  **Issue:** `How long does it take...` is fully correct.  
  **Suggested distractors:** `where`, `pay`, `need`

### `at-the-traffic`
- **Q13 / GrammarForm**  
  **Current:** `We ____ the tunnel.` | answer `are entering`  
  **Weak choice:** `entered`  
  **Issue:** `We entered the tunnel` is also grammatically correct without more context.  
  **Suggestion:** `Right now, we ____ the tunnel.`  
  **Suggested distractors:** `is entering`, `enters`, `enter`
- **Q14 / ClozeSequence**  
  **Current:** `Can you _____ the car please. I would like to _____.` | answer `stop`, `get out`  
  **Issue:** Punctuation/grammar problem.  
  **Suggestion:** `Can you _____ the car, please? I would like to _____.`  
  **Suggested distractors:** `follow`, `get in`, `drive`
- **Q15 / ClozeSequence**  
  **Current:** `It's a _____ and ______ road.` | answer `long`, `narrow`  
  **Weak choices:** `short`, `wide`, `busy`, `empty`  
  **Issue:** Many combinations are grammatical without context.  
  **Suggestion:** `The road is very long, but it is not wide. It is _____ and ______.`  
  **Suggested distractors:** `straight`, `smooth`, `safe`

### `kitchen`
- **Q11 / AppearDisappear**  
  **Current:** `I am very hungry today.`  
  **Weak choice:** `very`  
  **Issue:** Duplicate of a correct word; duplicate text can behave like another correct tile.  
  **Suggested distractors:** `too`, `really`, `now`

### `at-the-farm`
- **Q3 / ConvoTemplate-1**  
  **Current:** `The apples look so good! Can we ____ them now? / No, but we can _____ them next week.` | answer `pick`  
  **Weak choice:** `gather`  
  **Issue:** `gather them` can also be correct for apples.  
  **Suggested distractors:** `plant`, `wash`, `feed`
- **Q12 / GrammarForm**  
  **Current:** `It is important that we _____ more nutrients.` | answer `add`  
  **Weak choice:** `do add`  
  **Issue:** Emphatic `do add` is grammatically possible.  
  **Suggested distractors:** `adds`, `adding`, `added`

### `verb-to-be`
- **Q3 / GrammarForm**  
  **Current:** `I ___ a teacher` | answer `am`  
  **Weak choice:** `are  ot`  
  **Issue:** Typo/obviously invalid option.  
  **Suggested distractors:** `are`, `is`, `be`

### `at-the-office`
- **Q12 / GrammarForm**  
  **Current:** `Our team usually ____ a great job?` | answer `does`  
  **Issue:** Declarative word order with question mark.  
  **Suggestion:** `Our team usually ____ a great job.`  
  **Suggested distractors:** `do`, `did`, `doing`

### `baby-care`
- **Q14 / ClozeSequence**  
  **Current:** `Grandma _____ the baby's _____ little cheeks.` | answer `kisses`, `pretty`  
  **Weak choice:** `wipes`  
  **Issue:** `Grandma wipes the baby's pretty little cheeks` is plausible.  
  **Suggested distractors:** `feeds`, `rocks`, `dresses`

### `at-garage-gas station`
- **Q12 / GrammarForm**  
  **Current:** `Mechanic ____ only replace the battery tomorrow.` | answer `can`  
  **Issue:** Missing article before `Mechanic`; modal slot is also ambiguous.  
  **Suggestion:** `The mechanic ____ replace the battery today because the shop is closed.` | answer `can't`  
  **Suggested distractors:** `can`, `does`, `are`

### `nature-walk`
- **Q3 / ConvoTemplate-1**  
  **Current:** `What are you putting in your bag? / I am ______ leaves!` | answer `collecting`  
  **Weak choices:** `collecting`, `picking`  
  **Issue:** `collecting` duplicates the answer; `picking leaves` is also natural.  
  **Suggested distractors:** `counting`, `watching`, `drawing`
- **Q13 / GrammarForm**  
  **Current:** `Who _____ acorns?` | answer `collects`  
  **Weak choice:** `collect`  
  **Issue:** `Who collect acorns?` can be grammatical if `who` refers to plural people/animals.  
  **Suggestion:** `Which animal _____ acorns?`  
  **Suggested distractors:** `collect`, `collecting`, `can collects`
- **Q14 / ClozeSequence**  
  **Current:** `Small ants _____ _____ hills in the dry, sandy ground.` | answer `build`, `deep`  
  **Issue:** `deep hills` is not a natural collocation.  
  **Suggestion:** `Small ants _____ _____ in the dry, sandy ground.` | answer `build`, `anthills`  
  **Suggested distractors:** `carry`, `rocks`, `paths`
- **Q15 / ClozeSequence**  
  **Current:** `_______, a rabbit came out from the bushes.` | answer `suddenly`  
  **Weak choices:** `slowly`, `carefully`  
  **Issue:** Both can grammatically and plausibly complete the sentence.  
  **Suggestion:** `The bushes were quiet. _______, a rabbit jumped out.`  
  **Suggested distractors:** `yesterday`, `outside`, `nearby`

### `at-the-park`
- **Q5 / WordPairs**  
  **Current:** `everyday`  
  **Issue:** Frequency phrase should be `every day`; `everyday` means ordinary/common.  
  **Suggestion:** Change to `every day`.  
  **Suggested alternates:** `every day`, `once a day`, `twice a week`
- **Q12 / ClozeSequence**  
  **Current:** `Don't _____ too high or you might _____!` | answer `climb`, `fall`  
  **Weak choice:** `jump`  
  **Issue:** `Don't jump too high or you might fall` is natural.  
  **Suggested distractors:** `sit`, `read`, `sleep`
- **Q14 / GrammarForm**  
  **Current:** `You ________ the ball far so the dog gets some exercise.` | answer `should throw`  
  **Weak choice:** `might throw`  
  **Issue:** Also grammatical and plausible.  
  **Suggested distractors:** `throwing`, `throws`, `should throwing`
- **Q15 / ClozeSequence**  
  **Current:** `The children ____ and ______ near the fountain in the park.` | answer `play`, `have fun`  
  **Weak choices:** `climb`, `picniking`  
  **Issue:** `climb` can fit the first blank; `picniking` is misspelled.  
  **Suggested distractors:** `sleepy`, `quietly`, `homework`
- **Q16 / ConvoTemplate-1**  
  **Current:** `_____ dog is that? / He is a golden retriever.` | answer `what kind of`  
  **Weak choice:** `which type of`  
  **Issue:** Near-equivalent to correct answer.  
  **Suggested distractors:** `whose`, `which`, `how old`

### `at-the-restaurant`
- **Q6 / DialogueCompletion**  
  **Current:** `Can we take the bill?` | answer `Sure, how do you want to pay?`  
  **Issue:** `take the bill` is unnatural in restaurant English.  
  **Suggestion:** `Can we have the bill, please?`  
  **Suggested distractors:** `Sure, would you like dessert?`, `No, the menu is closed.`, `Yes, the table is ready.`
- **Q12 / ClozeSequence**  
  **Current:** `_____ dish is the most _____ on the menu?` | answer `which`, `delicious`  
  **Weak choices:** `what`, `tastless`  
  **Issue:** `What dish...` is also correct; `tastless` is misspelled.  
  **Suggested distractors:** `when`, `who`, `tasteless`

### `bedroom`
- **Q10 / WordPairs**  
  **Current:** `to me`  
  **Weak translation:** Chinese `大部头书`  
  **Issue:** Translation means a large book/tome, not `to me`.  
  **Suggestion:** Use Chinese `给我`.  
  **Suggested alternates:** `给我`, `给你`, `给他/她`

### `at-the-farmers-market`
- **Q5 / WordPairs**  
  **Current:** `free`  
  **Weak translations:** `özgür`, `livre`, `自由的`, `حر`, `मुक्त`  
  **Issue:** Market context needs `free` as no-cost, not liberated/free.  
  **Suggestion:** Use no-cost translations.  
  **Suggested alternates:** `free`, `no-cost`, `complimentary`
- **Q6 / DialogueCompletion**  
  **Current:** `Is this bread made today?` | answer `Yes, it is very fresh.`  
  **Weak choice:** `Yes, it is made yesterday.`  
  **Issue:** Prompt should be past/passive; distractor has tense mismatch.  
  **Suggestion:** `Was this bread made today?`  
  **Suggested distractors:** `No, it was made yesterday.`, `It will be made tomorrow.`, `No, these are yesterday's loaves.`
- **Q11 / ClozeSequence**  
  **Current:** `I _____ the ______ before I buy honey.` | answer `compare`, `prices`  
  **Weak choice:** `check`  
  **Issue:** `I check the prices...` is also correct.  
  **Suggested distractors:** `carry`, `wash`, `count`

### `at-the-hospital`
- **Q3 / ConvoTemplate-1**  
  **Current:** `You look sick. Let me _____ your temperature.` | answer `check`  
  **Weak choice:** `take`  
  **Issue:** `take your temperature` is also correct.  
  **Suggested distractors:** `ask`, `watch`, `write`

### `clothes-shopping`
- **Q2 / ConvoTemplate-1**  
  **Current:** `Excuse me, can I ____ on this coat, please?` | answer `try`  
  **Weak choice:** `put`  
  **Issue:** `put on this coat` is also correct.  
  **Suggested distractors:** `buy`, `wash`, `fold`
- **Q13 / GrammarForm**  
  **Current:** `I think you _____ this style.` | answer `will love`  
  **Weak choice:** `could love`  
  **Issue:** Also grammatical and plausible.  
  **Suggested distractors:** `will loving`, `loving`, `to love`

### `at-the-dentist`
- **Q6 / ConvoTemplate-1**  
  **Current:** `Does it ____ when I press here? / Yes, it ______.` | answer `hurt`  
  **Issue:** Same answer produces `Yes, it hurt`; should be `hurts` or `does`.  
  **Suggestion:** `Does it ____ when I press here? / Yes, it does.` | answer `hurt`  
  **Suggested distractors:** `pain`, `touch`, `hit`
- **Q11 / DialogueCompletion**  
  **Current:** `How often do you visit the dentist?` | answer `I visit the dentist every 6 months`  
  **Weak choice:** `I visit the dentist every week`  
  **Issue:** It directly answers the open-ended question and could be true.  
  **Suggestion:** `How often should most people visit the dentist for a regular checkup?` | answer `Every 6 months.`  
  **Suggested distractors:** `Every day.`, `Every hour.`, `Never.`

### `going-to-sports`
- **Q7 / AppearDisappear**  
  **Current:** `She was so tired to finish the marathon.`  
  **Issue:** Grammar error; should be `too tired to finish` or `so tired that...`.  
  **Suggestion:** `She was too tired to finish the marathon.`  
  **Suggested distractors:** `very`, `enough`, `that`
- **Q10 / ClozeSequence**  
  **Current:** `It is ____ to ____ in cold water every morning.` | answer `tough`, `swim`  
  **Weak choice:** `possible`  
  **Issue:** `It is possible to swim...` is also correct.  
  **Suggested distractors:** `easy`, `sleep`, `drive`

### `at-the-school`
- **Q12 / AppearDisappear**  
  **Current:** `Teacher asks an easy question.`  
  **Issue:** Missing article.  
  **Suggestion:** `The teacher asks an easy question.`  
  **Suggested distractors:** `student`, `difficult`, `answers`

### `at-the-bank`
- **Q3 / ConvoTemplate-1**  
  **Current:** `I need to ______ some cash.` | answer `withdraw`  
  **Weak choices:** `deposit`, `transfer`  
  **Issue:** Both can fit naturally in a bank context.  
  **Suggestion:** `I need to ______ some cash from my account.`  
  **Suggested distractors:** `save`, `spend`, `open`

### `basic-sentences`
- **Q12 / GrammarForm**  
  **Current:** `I ___ the sunshine every day` | answer appears as `["see"]`  
  **Issue:** `GrammarForm` answers should be a string, not an array.  
  **Suggestion:** Change answer to `see`.  
  **Suggested distractors:** `saw`, `having see`, `seeing`

## Notes
- Removed lower-confidence items from the previous report where the alternate answer was only weakly plausible or the suggested fix was not clearly better.
- Did not flag `ClozeSequence` using `answers` instead of `answer`, because the parser supports both.
- Files with no non-image questions or no high-confidence non-image issues are intentionally omitted from the flagged list.
