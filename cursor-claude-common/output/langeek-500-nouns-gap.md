# LanGeek 500 nouns — vocabulary gap analysis

**Question:** Which LanGeek common nouns are *not* yet represented in the game?

## Data compared

| Source | Count |
|--------|------:|
| LanGeek noun list | 500 |
| Level PNG files (`quiz-data/levels/**/*.png`) | 805 |
| `translations.json` → `english_word` | 445 |
| WordPairs → `english_words` | 153 |

Matching rules: hyphenated PNG stems split into tokens; plural/singular treated as equivalent (`people`↔`person`, `women`↔`woman`, regular `-s`/`-ies`); skip leading `the`/`a`/`an`/`to` when comparing tokens; no substring/stem matching (`musician` ≠ `music`).

## Summary

- **Covered:** 178 / 500 (35.6%)
- **Gap:** 322 / 500 (64.4%)

## Gap by frequency band

### Top 1–100 — 55 missing

guy, part, today, number, point, word, music, place, fact, problem, body, country, story, example, state, stuff, reason, power, food, system, game, company, minute, hour, second, job, level, moment, business, law, bit, line, area, group, sense, mind, issue, space, couple, student, information, process, decision, kid, phone, experience, history, piece, type, energy, face, government, city, health, audience

### Top 101–250 — 96 missing

team, product, color, deal, amount, air, comment, difference, community, president, situation, language, channel, lady, crime, step, death, cell, dollar, camera, voice, value, member, relationship, laughter, girl, data, war, force, version, town, option, trip, chance, test, effect, program, evening, event, husband, wife, education, class, conversation, court, position, rate, rule, thought, party, size, ground, course, risk, opportunity, service, image, song, skin, series, period, technology, attention, age, result, field, ability, disease, research, narrator, record, role, list, season, bunch, development, choice, production, emotion, note, dude, enemy, joke, peace, task, habit, content, century, decade, fan, project, planet, damage, election, reality, device

### Top 251–400 — 95 missing

human, theory, weight, condition, message, challenge, source, degree, view, feeling, beginning, middle, page, center, experiment, advice, sex, television, material, applause, evidence, support, population, skill, training, industry, nature, mile, truth, quality, leader, culture, photograph, mom, dad, letter, website, response, brand, environment, matter, surface, the Internet, section, shape, lesson, policy, memory, item, success, engine, feature, purpose, style, blindness, society, stock, function, hearing, vision, nation, individual, sentence, benefit, shot, structure, impact, pattern, object, career, edge, fear, customer, effort, temperature, activity, access, charge, campaign, mistake, instance, text, loss, strategy, bone, continent, solution, vote, generation, argument, bar, battle, spot, email, chocolate

### Top 401–500 — 76 missing

site, advantage, hole, connection, economy, flavor, performance, method, college, trial, knowledge, property, diet, document, speech, reaction, network, range, distance, background, foreground, gun, element, layer, justice, expert, army, navy, air force, universe, corner, track, trouble, behavior, organization, cause, freedom, income, threat, soul, trick, investment, factor, supply, location, strength, virus, suit, vehicle, wave, restaurant, opinion, statement, region, metal, topic, king, queen, report, path, growth, stress, weapon, noise, treatment, trade, cancer, vaccine, perspective, partner, belief, mission, subject, technique, client, boss

## Full gap list (ranked)

10. guy
12. part
13. today
17. number
18. point
19. word
21. music
22. place
27. fact
29. problem
32. body
33. country
34. story
35. example
36. state
40. stuff
44. reason
47. power
48. food
49. system
50. game
52. company
53. minute
54. hour
55. second
56. job
58. level
59. moment
60. business
61. law
62. bit
63. line
64. area
65. group
66. sense
68. mind
72. issue
74. space
75. couple
76. student
78. information
79. process
80. decision
81. kid
82. phone
85. experience
86. history
87. piece
88. type
89. energy
90. face
92. government
95. city
97. health
99. audience
102. team
103. product
104. color
106. deal
107. amount
108. air
110. comment
112. difference
113. community
116. president
118. situation
119. language
120. channel
122. lady
124. crime
126. step
129. death
130. cell
132. dollar
133. camera
134. voice
137. value
138. member
139. relationship
140. laughter
141. girl
143. data
144. war
145. force
147. version
148. town
149. option
150. trip
151. chance
152. test
154. effect
156. program
160. evening
162. event
164. husband
165. wife
168. education
170. class
171. conversation
172. court
174. position
175. rate
176. rule
177. thought
178. party
179. size
180. ground
181. course
182. risk
183. opportunity
185. service
187. image
189. song
191. skin
192. series
195. period
198. technology
199. attention
200. age
201. result
203. field
206. ability
208. disease
209. research
210. narrator
211. record
212. role
213. list
215. season
216. bunch
217. development
218. choice
224. production
225. emotion
229. note
230. dude
231. enemy
232. joke
233. peace
234. task
235. habit
237. content
238. century
239. decade
241. fan
242. project
244. planet
245. damage
246. election
247. reality
248. device
252. human
253. theory
254. weight
256. condition
257. message
258. challenge
259. source
263. degree
265. view
266. feeling
267. beginning
268. middle
270. page
271. center
272. experiment
273. advice
274. sex
275. television
278. material
279. applause
280. evidence
283. support
286. population
289. skill
290. training
292. industry
293. nature
295. mile
296. truth
297. quality
298. leader
299. culture
300. photograph
301. mom
302. dad
305. letter
306. website
307. response
308. brand
309. environment
314. matter
315. surface
317. the Internet
318. section
320. shape
321. lesson
322. policy
324. memory
326. item
327. success
330. engine
331. feature
333. purpose
336. style
338. blindness
339. society
341. stock
343. function
349. hearing
350. vision
351. nation
352. individual
353. sentence
354. benefit
355. shot
356. structure
357. impact
358. pattern
361. object
362. career
363. edge
364. fear
365. customer
366. effort
367. temperature
368. activity
370. access
371. charge
372. campaign
373. mistake
374. instance
375. text
377. loss
381. strategy
383. bone
384. continent
388. solution
389. vote
390. generation
392. argument
394. bar
395. battle
396. spot
397. email
398. chocolate
401. site
402. advantage
404. hole
407. connection
408. economy
409. flavor
410. performance
412. method
415. college
416. trial
417. knowledge
418. property
420. diet
421. document
422. speech
423. reaction
424. network
427. range
429. distance
430. background
431. foreground
432. gun
433. element
434. layer
435. justice
436. expert
437. army
438. navy
439. air force
442. universe
443. corner
444. track
445. trouble
446. behavior
448. organization
450. cause
451. freedom
452. income
453. threat
454. soul
455. trick
456. investment
457. factor
458. supply
459. location
460. strength
462. virus
463. suit
464. vehicle
465. wave
466. restaurant
467. opinion
468. statement
469. region
470. metal
471. topic
472. king
473. queen
475. report
478. path
479. growth
480. stress
481. weapon
483. noise
484. treatment
485. trade
486. cancer
489. vaccine
491. perspective
492. partner
494. belief
496. mission
497. subject
498. technique
499. client
500. boss

## Covered nouns (for reference)

people, thing, time, way, year, month, day, coffee, life, world, man, woman, question, case, idea, money, person, water, work, side, hand, week, friend, end, car, book, name, sea, family, child, home, head, thanks, eye, order, school, room, movie, show, house, light, sound, brain, foot, animal, change, right, heart, top, answer, blood, baby, tongue, soldier, price, adult, form, love, door, tomorrow, boy, plan, market, picture, morning, noon, afternoon, night, news, son, daughter, back, half, hair, parent, box, egg, wall, fun, mother, father, tree, button, office, goal, pressure, fight, paper, police, tool, star, oil, land, computer, building, patient, plant, table, use, tonight, bottom, pain, store, glass, science, arm, window, battery, call, attack, bed, art, machine, account, cost, speed, fish, bird, key, the past, future, the present, drug, turn, street, help, sister, brother, ball, leg, dream, detail, need, while, practice, road, heat, ice, meal, sleep, hospital, meat, cheese, ship, date, race, finger, Earth, sun, moon, rock, meeting, check, bag, bank, front, cake, tooth, gas, floor, plane, sale, scale, shoe, hope, muscle, security, wind, milk, salt, file, talk, gold, the ocean, fruit, ear, cup, break
