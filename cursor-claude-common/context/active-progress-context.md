# Active Progress Context

## Issue-18: Content completion for quizzes

Description: The content will be completed for the game quizzes to be comlete.

Use Cases:

- For every quiz level folder (e.g. airport-1) make sure that there is a questions.json file so quiz will work without any error.
- In every questions.json make sure all the images under the folder is added as a question to the folder in an arbitatry order.
- To use as a reference for future implementations, as an example, user kitchen-1 folder
    - Add 5 conversation and grammar questions (3 vocab, 2 grammar) int the questions folder
    - Make vocabulary questions as existing vocab question format, a conversation piece talk that will be in the context of the folder (kitchen). That will require creatively generating a converation talk that will take place in kitchen. Make the answer and words relevant to the context. MAKE SURE that the question and answers are not one of the image items. For example don't create a conversation where the close word is can-opener since can-opener is in the images. The vocabulary can be mostly not an object, but a verb, like "cutting".
    - Make grammar question about the kitchen context but most the a grammar question as explained in the grammar quiz issue ticket previously.