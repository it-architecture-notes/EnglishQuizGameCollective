Description: The logic of of how visual game level maps will be generated is explained.

Use cases:
- When the user comes to a level map, they see the last completed (at least one star) level at the top and level-to-play-next in the second place from the top. This behaviour does not change whether the last played level is a reminder level or regular level.
- When the user goes in a quiz these are the options:
    - This is a quiz which is the furthest user achieved to reach (reminder or not) and either never played or played or finished with zero stars, otherwise it would not be the furthest level, it would be a completed level and there would be another level furhest. In this type of quiz:
        - If the user finishes with alt least a star and comes back to level screen, this level will be at the top and next level-to-be-played will be 2nd from top.
        - If user does not finish (quit) or finish with less than one star, the previous level will be at the top and this level will be 2nd from top to be played again.
    - This is a quiz not furthest, it was already played previously and user replays again to gain more diamonds or stars. It cannot be a reminder level because reminder levels do not have stars and cannot be replayed.
        - If it is a regular level and the user finishes with at least with 1 star or a reminder level and user finishes, and come back to level screen, this level will be at the top and the next-to-be-played level will be 2nd from top regardless or regular or reminder level.
        - User either quits in the middle or user finishes regardless of how. This specific finished level is 2nd from top (unless it's the first quiz) and the previous (alraeady played) level is at the top.
- The logic of showing 10 unlocked levels and loading levels when scrolling up remains as is.
