
## /lib/providers/localization_provider.dart

## /lib/providers/settings_provider.dart

class SettingsState extends Object
    SettingsState copyWith(String? language, bool? musicOn, bool? soundFxOn)
  get language
  get musicOn
  get soundFxOn

class SettingsNotifier extends StateNotifier
    Future<void> _load()
    Future<void> setLanguage(String lang)
    Future<void> setMusicOn(bool value)
    Future<void> setSoundFxOn(bool value)

## /lib/models/level_config.dart

class ImageQuestionData extends Object
  get imageName
  get wrongAnswers
  get answer

class ImageQuizTemplate2Data extends Object
  get imageName
  get wrongAnswers
  get answer
  get correctAnswerStem

class AppearDisappearQuestionData extends Object
  get words
  get distractors
  get displayDuration
  get introPause

class ClozeSequenceQuestionData extends Object
  get sentence
  get answers
  get distractors
  get imageName

class ConvoQuestionData extends Object
  get character1
  get character2
  get line1
  get line2
  get answer
  get distractors
  get line1Translation
  get line2Translation
  get imageName

class ConvoTemplate2QuestionData extends Object
  get imageName
  get sentence
  get answer
  get distractors

class SentenceBuilderQuestionData extends Object
  get correctOrder
  get translation

class WordPairItem extends Object
    String rightForLanguage(String userLanguage)
  get left
  get translations

class WordPairsQuestionData extends Object
  get pairs

class GrammarFormQuestionData extends Object
  get sentence
  get answer
  get distractors
  get translation

class DialogueCompletionQuestionData extends Object
  get character1
  get character2
  get line1
  get answer
  get distractors
  get line1Translation
  get answerTranslation
  get imageName

class LevelQuestion extends Object
  get questionId
  get audioFile
  get audioFile1
  get audioFile2
  get type
  get template
  get imageData
  get imageQuiz2Data
  get convoData
  get convo2Data
  get appearDisappearData
  get clozeSequenceData
  get sentenceBuilderData
  get wordPairsData
  get grammarFormData
  get dialogueCompletionData
  get appearDisappearTranslation

class LevelConfig extends Object
    LevelQuestionType _parseType(String raw)
    Map<String, String> _stringMap(dynamic value)
    Map<String, String>? _stringMapOrNull(dynamic value)
    ImageQuestionData _parseImageData(Map<String, dynamic> data)
    ImageQuizTemplate2Data _parseImageQuiz2Data(Map<String, dynamic> data)
    List<String> _stringList(dynamic v)
    List<String> _wordsFromArrayOrSentence(dynamic v)
    AppearDisappearQuestionData _parseAppearDisappear(Map<String, dynamic> data)
    bool _isBlankToken(String s)
    int _countBlanks(Map<String, String> sentence)
    ClozeSequenceQuestionData _parseClozeSequence(Map<String, dynamic> data)
    ClozeSequenceQuestionData _parseConvo2AsCloze(Map<String, dynamic> data)
    ConvoQuestionData _parseConvoData(Map<String, dynamic> data)
    ConvoTemplate2QuestionData _parseConvo2Data(Map<String, dynamic> data)
    SentenceBuilderQuestionData _parseSentenceBuilder(Map<String, dynamic> data)
    WordPairsQuestionData _parseWordPairs(Map<String, dynamic> data)
    GrammarFormQuestionData _parseGrammarForm(Map<String, dynamic> data)
    DialogueCompletionQuestionData _parseDialogueCompletion(Map<String, dynamic> data)
    LevelQuestion _parseQuestion(Map<String, dynamic> json)
  get questions
  get timerSeconds

## /lib/models/story_progress.dart

class StoryProgressState extends Object
    bool isCompleted(int mainLevelId, int eventId)
    StoryProgressState markCompleted(int mainLevelId, int eventId)
    Map<String, dynamic> toJson()
    StoryProgressState fromJson(Map<String, dynamic> json)
  get completedEventIdsByMainLevel

## /lib/models/quiz_flow.dart

class SubLevel extends Object
    SubLevel fromJson(Map<String, dynamic> json)
  get mainLevel
  get iconImageName
  get title
  get kind
  get reminderIndex
  get isReminder
  get progressKey

class MainLevelMeta extends Object
    MainLevelMeta fromJson(Map<String, dynamic> json)
  get mainLevel
  get title

class LevelListItem extends Object

class BannerItem extends LevelListItem
  get meta

class SubLevelItem extends LevelListItem
  get sub
  get ordinalLevelIndex
  get progressKey

## /lib/models/story_config.dart

class StoryTrigger extends Object
    StoryTrigger fromJson(Map<String, dynamic> json)
  get type
  get level

class StoryPageConfig extends Object
    String localizedStoryText(String languageCode)
    StoryPageConfig fromJson(Map<String, dynamic> json)
  get eventId
  get pageTemplateId
  get trigger
  get coveredLevelsNumber
  get pageTextListForTemplate
  get pageImageListForTemplate
  get pageAnimationListForTemplate
  get storyText

class MainLevelStoryConfig extends Object
    MainLevelStoryConfig fromJson(Map<String, dynamic> json)
  get mainLevelId
  get storyIconAssetPath
  get storySequences

class StoryTemplateConfig extends Object
    StoryTemplateConfig fromJson(Map<String, dynamic> json)
  get templateId
  get layout
  get requiresText
  get requiresImages
  get requiresAnimation

class StoryConfigData extends Object
    MainLevelStoryConfig? storyForMainLevel(int mainLevelId)
  get mainLevels
  get templatesById

## /lib/models/friends_state.dart

class FriendsState extends Object
    Map<String, dynamic> toJson()
    FriendsState fromJson(Map<String, dynamic> json)
    FriendsState copyWith(Set<String>? freedAnimalIds, bool? hintDismissed)
  get freedAnimalIds
  get hintDismissed

## /lib/models/profile_state.dart

class ProfileState extends Object
    ProfileState copyWith(String? userId, String? dateJoinedIso, String? avatarName, String? avatarAssetPath, bool clearAvatarAssetPath, String? lastPlayedDay, int? currentStreak, Map<String, int>? totalQuestionsAnsweredByQuizType)
    Map<String, dynamic> toJson()
    ProfileState fromJson(Map<String, dynamic> json)
    Map<String, int> _intMap(dynamic value)
    Map<String, String> _stringMap(dynamic value)
  get userId
  get dateJoinedIso
  get avatarName
  get avatarAssetPath
  get lastPlayedDay
  get currentStreak
  get totalQuestionsAnsweredByQuizType
  get defaultAvatarName

## /lib/models/reminder_progress.dart

class ReminderLevelState extends Object
    ReminderLevelState copyWith(bool? isCompleted, List<String>? questionIds)
    Map<String, dynamic> toJson()
    ReminderLevelState fromJson(Map<String, dynamic> json)
  get isCompleted
  get questionIds

class ReminderProgressData extends Object
    ReminderLevelState reminderState(int mainLevel, int reminderIndex)
    bool isReminderCompleted(int mainLevel, int reminderIndex)
    ReminderProgressData copyWith(Map<String, int>? wrongAnswerCounters, Map<int, List<ReminderLevelState>>? remindersByMainLevel)
    Map<String, dynamic> toJson()
    ReminderProgressData fromJson(Map<String, dynamic> json)
  get wrongAnswerCounters
  get remindersByMainLevel
  String buildReminderQuestionId(String progressKey, int questionIndex)
  (String, int) parseReminderQuestionId(String questionId)

## /lib/models/level_completion_result.dart

class LevelCompletionResult extends Object
  get ordinalLevelIndex
  get completed
  get isReminder

## /lib/models/guest_animal_conversations.dart

class StepChoice extends Object
    StepChoice fromJson(Map<String, dynamic> json)
  get attacker
  get guest

class LanguageConversations extends Object
    List<StepChoice> choicesForStep(int step)
    LanguageConversations fromJson(Map<String, dynamic> json)
    List<StepChoice> _parseChoices(dynamic value)
  get language
  get step1Choices
  get step2Choices
  get step3Choices
  get step4Choices

class GuestAnimalConversationsConfig extends Object
  get conversations

## /lib/models/achievement_state.dart

class AchievementState extends Object
    Map<String, dynamic> toJson()
    AchievementState fromJson(Map<String, dynamic> json)
    AchievementState copyWith(int? bestQuizTimeSeconds, int? currentCorrectStreak, bool clearBestQuizTime)
  get bestQuizTimeSeconds
  get currentCorrectStreak

## /lib/screens/profile_panel_screen.dart

class _ProfileOverlayRoute extends StatelessWidget
    Widget build(BuildContext context)

class ProfilePanelScreen extends StatefulWidget
    State<ProfilePanelScreen> createState()
  get overlayMode

class _ProfilePanelScreenState extends State
    void initState()
    void dispose()
    Future<void> _load()
    Future<void> _closeAndSave()
    Future<void> _openAvatarPicker()
    Widget build(BuildContext context)
    Widget _buildOverlayContent()
    Widget _buildFullScreen()
    Widget _buildBody()
    Widget _buildIdentitySection(ProfileState profile)
    void _syncNameFromController()
    Widget _buildAvatarPreview(ProfileState profile)
    Widget _buildLifetimeRow(ProfileSummary summary)
    Widget _buildStatChip(IconData icon, Color color, String label, String sublabel)
    Widget _buildQuizTypeRow(QuizTypeProfileStats stats)
    Widget _buildMiniStat(IconData icon, String value, String label)
    String _formatDate(String iso)
    String _titleCase(String input)
  get _profile
  set _profile=
  get _summary
  set _summary=
  get _avatarAssets
  set _avatarAssets=
  get _isLoading
  set _isLoading=
  get _isSaving
  set _isSaving=
  get _error
  set _error=
  get _nameController
  void showProfilePanelOverlay(BuildContext context)

## /lib/screens/achievements_panel_content.dart

class AchievementsPanelContent extends StatefulWidget
    State<AchievementsPanelContent> createState()

class _AchievementsPanelContentState extends State
    void initState()
    Future<void> _load()
    Widget build(BuildContext context)
  get _progress
  set _progress=
  get _error
  set _error=
  get _loading
  set _loading=

class _AchievementTile extends StatelessWidget
    Widget build(BuildContext context)
    Widget _fallbackIcon(BuildContext context, bool unlocked)
    String _progressLabel(AchievementDefinition def, AchievementProgress p)
  get progress

## /lib/screens/quiz_runner_screen.dart

class QuizRunnerScreen extends ConsumerStatefulWidget
    ConsumerState<QuizRunnerScreen> createState()
  get subLevel
  get ordinalLevelIndex
  get progressKey
  get reminderMode
  get reminderQuestionIds
  get reminderSourceLevelsByProgressKey

class _QuizRunnerScreenState extends ConsumerState
    void initState()
    Future<void> _run()
    Future<void> _runRegular()
    Future<void> _runReminder()
    void _popToLevels(BuildContext context)
    Widget build(BuildContext context)
  get _error
  set _error=

## /lib/screens/placeholders/settings_placeholder_screen.dart

class SettingsPlaceholderScreen extends StatelessWidget
    Widget build(BuildContext context)

## /lib/screens/placeholders/profile_placeholder_screen.dart

class ProfilePlaceholderScreen extends StatelessWidget
    Widget build(BuildContext context)

## /lib/screens/placeholders/level_selection_placeholder_screen.dart

class LevelSelectionPlaceholderScreen extends StatelessWidget
    Widget build(BuildContext context)
  get title

## /lib/screens/placeholders/quiz_placeholder_screen.dart

class QuizPlaceholderScreen extends StatelessWidget
    Widget build(BuildContext context)
  get quizType
  get subLevel
  get ordinalLevelIndex

## /lib/screens/placeholders/achievements_placeholder_screen.dart

class AchievementsPlaceholderScreen extends StatelessWidget
    Widget build(BuildContext context)

## /lib/screens/placeholders/friends_placeholder_screen.dart

class FriendsPlaceholderScreen extends StatelessWidget
    Widget build(BuildContext context)

## /lib/screens/image_quiz_screen.dart

class ImageQuizScreen extends ConsumerStatefulWidget
    ConsumerState<ImageQuizScreen> createState()
  get preloadedLevelConfig
  get subLevel
  get ordinalLevelIndex
  get progressKey
  get reminderMode
  get reminderQuestionIds
  get reminderSourceLevelsByProgressKey

class _ImageQuizScreenState extends ConsumerState
    String _levelKey(SubLevel sub)
    String? _convoAnswer(LevelQuestion? q)
    void initState()
    void dispose()
    Future<void> _loadLevel()
    Future<void> _loadReminderLevel()
    int _timerSecondsForCurrentQuestion()
    bool _currentQuestionIsMonsterEligible()
    void _startTimer()
    void _onTimerExpired()
    void _recordWrongForMonster()
    Widget _animalImage(int step)
    Widget _monsterImage()
    String _correctAnswer()
    List<String> _buildOptions()
    void _onAnswerTap(int optionIndex)
    void _goNext()
    String? _audioAssetPathForRaw(String? raw)
    String? _audioAssetPath(LevelQuestion q)
    Future<bool> _resolveAudioExists(String path)
    int _stars()
    int _diamondsEarned()
    Future<void> _onEndOk()
    Widget build(BuildContext context)
    Widget _buildBody(bool soundFxOn, Map<String, String> strings, String userLanguage)
    Widget _buildLoading(bool soundFxOn, Map<String, String> strings)
    ImageQuizTemplate2Data? _currentImageQuiz2Data()
    List<String>? _fourOrderedPathsForCurrentImageQuiz2()
    String _nounLabelFromImageStem(String stem)
    String? _assetPathForImageQuiz2Stem(ImageQuizTemplate2Data d, List<String> fourOrdered, String stem)
    double _autoAdvanceDelayForCurrentImageQuestion()
    void _handleInteractiveConvoOutcome(LevelQuestion q, bool correct)
    Widget _buildImagePlaying(bool soundFxOn, Map<String, String> strings, String userLanguage)
    Widget _buildEnd(bool soundFxOn, Map<String, String> strings)
    Widget _buildGameOver(bool soundFxOn, Map<String, String> strings)
    Widget _buildConvoPlaying(bool soundFxOn, Map<String, String> strings, String userLanguage)
    Widget _buildConvoQuestionBody(LevelQuestion q, String userLanguage, bool soundFxOn, Map<String, String> strings)
    String? _resolvedClozeImagePath()
    String _questionLabel(Map<String, String> strings, int current, int total)
    String _titleForTemplate(String template, Map<String, String> strings)
    String? _convo1CombinedTranslation(ConvoQuestionData q, String lang)
    Widget _convo1AudioControls(LevelQuestion q)
    Widget _buildCharactersRow(ConvoQuestionData q, String userLanguage)
    Widget _buildCharacterColumn(String name, String dialogueLine, bool isActive, CrossAxisAlignment alignment)
    Widget _buildCharacterAvatar(String name, double size)
    Widget _buildDialogueBubble(String text, bool isActive, bool alignRight)
    Widget _buildBubbleText(String text, bool isActive)
    Widget _buildConvoAnswerButton(int optionIndex, LevelQuestion q, bool soundFxOn)
    String _capitalize(String s)
  get _phase
  set _phase=
  get _loadError
  set _loadError=
  get _questionAssetPaths
  set _questionAssetPaths=
  get _currentQuestionIds
  set _currentQuestionIds=
  get _initialReminderQuestionIds
  set _initialReminderQuestionIds=
  get _nextReviewQuestionIds
  get _assetPathByQuestionId
  get _vocabularyByQuestionId
  get _vocabulary
  set _vocabulary=
  get _configWrongAnswers
  set _configWrongAnswers=
  get _configImageQuestions
  set _configImageQuestions=
  get _configImageQuiz2Paths
  set _configImageQuiz2Paths=
  get _reminderImageQuiz2PathsByQuestionId
  get _reminderImageQuestionsById
  get _config
  set _config=
  get _currentIndex
  set _currentIndex=
  get _correctCount
  set _correctCount=
  get _previousHighestDiamonds
  set _previousHighestDiamonds=
  get _shortQuizDebug
  set _shortQuizDebug=
  get _endedEarlyShortQuiz
  set _endedEarlyShortQuiz=
  get _answerLocked
  set _answerLocked=
  get _showNext
  set _showNext=
  get _reviewingMistakes
  set _reviewingMistakes=
  get _initialQuestionCount
  set _initialQuestionCount=
  get _selectedIndex
  set _selectedIndex=
  get _convoTtsPlaying
  set _convoTtsPlaying=
  get _currentOptions
  set _currentOptions=
  get _quizStartTime
  set _quizStartTime=
  get _timerController
  set _timerController=
  get _monsterStep
  set _monsterStep=
  get _monsterEligibleWrongCount
  set _monsterEligibleWrongCount=
  get _monsterEligibleQuestionCount
  set _monsterEligibleQuestionCount=
  get _guestAnimal
  set _guestAnimal=
  get _selectedMonster
  set _selectedMonster=
  get _windController
  set _windController=
  get _monsterIdleController
  set _monsterIdleController=
  get _conversations
  set _conversations=
  get _bubbleConversation
  set _bubbleConversation=
  get _gameOverBubble
  set _gameOverBubble=
  get _convoQuestions
  set _convoQuestions=
  get _convo2HeroPaths
  set _convo2HeroPaths=
  get _convoByQuestionId
  get _convo2ImagePathByQuestionId
  get _allQuestions
  set _allQuestions=
  get _questionImagePaths
  set _questionImagePaths=
  get _questionQuiz2Paths
  set _questionQuiz2Paths=
  get _questionConvo2HeroPaths
  set _questionConvo2HeroPaths=
  get _audioExistsCache
  get _levelTimerSeconds
  set _levelTimerSeconds=
  get _isReminder
  get _currentQuestionId
  get _isConvoMode
  get _currentConvoLevelQuestion
  get _questionCount
  get _displayQuestionIndexOneBased
  get _displayQuestionTotal
  get _showMonsterLaneForCurrentQuestion
  get _currentLevelQuestion

class _SpeechBubble extends StatelessWidget
    Widget build(BuildContext context)
  get text
  get maxWidth

class _PieTimerPainter extends CustomPainter
    void paint(Canvas canvas, Size size)
    bool shouldRepaint(_PieTimerPainter old)
  get progress
  get color

class _WindPainter extends CustomPainter
    void paint(Canvas canvas, Size size)
    bool shouldRepaint(_WindPainter oldDelegate)
  get value
  bool _isMonsterEligibleImageTemplate(String template)
  int _monsterStepFromEligibleWrongs(int eligibleWrongCount, int eligibleQuestionCount)

## /lib/screens/levels_screen.dart

class _LayoutRow extends Object

class _BannerLayoutRow extends _LayoutRow
  get meta

class _SubsLayoutRow extends _LayoutRow
  get subLevelItem

class LevelsScreen extends ConsumerStatefulWidget
    ConsumerState<LevelsScreen> createState()

class _LevelsScreenState extends ConsumerState
    void initState()
    void dispose()
    int? _findPreviousSubLevelOrdinal(List<LevelListItem> filtered, int ordinalLevelIndex)
    int _findScrollStartIndex(List<LevelListItem> filtered, QuizTypeProgress progress, int? anchorOrdinal)
    List<SubLevelItem> _regularSubLevelsFrom(List<LevelListItem> items)
    Map<String, SubLevelItem> _regularSourceLevelsByMain(int mainLevel)
    SubLevelItem? _firstRegularItemForMain(int mainLevel, Iterable<SubLevelItem>? regularFlowSubLevels)
    Set<String> _computeUnlockedKeys(Iterable<SubLevelItem> regularItems, QuizTypeProgress progress)
    bool _isRegularLevelUnlocked(SubLevelItem item, QuizTypeProgress progress, Iterable<SubLevelItem>? regularFlowSubLevels, ReminderProgressData? reminderProgress)
    bool _isReminderCompleted(SubLevelItem item)
    bool _isReminderUnlocked(SubLevelItem item)
    int _lastRegularLocalLevel(int mainLevelId, Iterable<SubLevelItem> regularFlow)
    bool _shouldGateAfterStoryPage(StoryPageConfig page, int mainLevelId, Iterable<SubLevelItem> regularFlowSubLevels)
    Future<void> _loadData(int? anchorOrdinal)
    Future<void> _freshLoadData(int? anchorOrdinal)
    Future<StoryProgressState> _syncCompletedStoryPages(StoryConfigData storyConfig, StoryProgressState storyProgress, QuizTypeProgress progress, List<LevelListItem> allItems)
    void _onScroll()
    List<LevelListItem> _applyFilter(List<LevelListItem> rawItems, QuizTypeProgress progress, ReminderProgressData reminderProgress)
    String _titleFromStrings(Map<String, String> strings)
    Widget build(BuildContext context)
    Widget _buildRow(BuildContext context, _LayoutRow row, int globalSubRowIndex)
    Widget _buildBanner(BuildContext context, MainLevelMeta meta)
    Widget _buildStoryIcon(BuildContext context, bool isUnlocked, String? iconPath)
    Widget _buildSubLevelRow(BuildContext context, int globalSubRowIndex, SubLevelItem subLevelItem)
    Widget _buildSubLevelCell(BuildContext context, SubLevelItem subLevelItem, double iconSize, bool isLocked, int stars, bool isCompletedReminder)
    Future<Map<String, int>> _buildRegularQuestionCountsForMain(int mainLevel)
    Future<void> _ensureReminderQuestionsGenerated(int mainLevel)
    Route<LevelCompletionResult> _buildQuizRoute(SubLevelItem subLevelItem, bool reminderMode, List<String>? reminderQuestionIds, Map<String, SubLevelItem>? reminderSourceLevelsByProgressKey)
    void _openQuiz(BuildContext context, SubLevelItem subLevelItem)
    Future<void> _showBeforeStoryIfNeeded(SubLevelItem subLevelItem)
    Future<void> _showStoryPage(StoryPageConfig page)
  get _items
  set _items=
  get _filtered
  set _filtered=
  get _progress
  set _progress=
  get _reminderProgress
  set _reminderProgress=
  get _storyConfig
  set _storyConfig=
  get _storyProgress
  set _storyProgress=
  get _windowStart
  set _windowStart=
  get _windowEnd
  set _windowEnd=
  get _loadError
  set _loadError=
  get _loading
  set _loading=
  get _itemScrollController
  set _itemScrollController=
  get _itemPositionsListener
  set _itemPositionsListener=
  get _batchSize
  get _sinFrequency
  get _maxLockedPreview
  get _regularSubLevels
  get _visibleLayoutRows
  List<LevelListItem> buildLevelItems(QuizFlowData data)
  List<_LayoutRow> _itemsToLayoutRows(List<LevelListItem> items)

## /lib/screens/friends_panel_content.dart

class FriendsPanelContent extends StatefulWidget
    State<FriendsPanelContent> createState()

class _FriendsPanelContentState extends State
    void initState()
    Future<void> _load()
    Future<void> _showHintDialog()
    void _onTapAnimal(FriendAnimalDefinition def)
    Widget build(BuildContext context)
  get _definitions
  set _definitions=
  get _friendsState
  set _friendsState=
  get _availableDiamonds
  set _availableDiamonds=
  get _error
  set _error=
  get _loading
  set _loading=
  get _justFreedId
  set _justFreedId=

class _FriendTile extends StatefulWidget
    State<_FriendTile> createState()
  get definition
  get isFreed
  get justFreed
  get onTap
  get onAnimationDone

class _FriendTileState extends State
    void initState()
    void didUpdateWidget(_FriendTile oldWidget)
    void dispose()
    Color _placeholderColor(String id)
    Widget _buildPlaceholderBox(Color placeColor, bool isFreed)
    Widget build(BuildContext context)
  get _controller
  set _controller=
  get _scale
  set _scale=
  get _offset
  set _offset=

## /lib/screens/quiz_templates/grammar_form_quiz_body.dart

class GrammarFormQuizBody extends StatefulWidget
    State<GrammarFormQuizBody> createState()
  get data
  get userLanguage
  get translation
  get onPlayCorrect
  get onPlayWrong
  get onOutcome

class _GrammarFormQuizBodyState extends State
    void initState()
    void _onTap(int i)
    Widget build(BuildContext context)
  get _options
  set _options=
  get _locked
  set _locked=
  get _selectedIndex
  set _selectedIndex=
  get _correctIndex
  set _correctIndex=

## /lib/screens/quiz_templates/sentence_builder_quiz_body.dart

class SentenceBuilderQuizBody extends StatefulWidget
    State<SentenceBuilderQuizBody> createState()
  get data
  get strings
  get userLanguage
  get translation
  get audioAssetPath
  get resolveAudioExists
  get onPlayQuestionAudio
  get onPlayCorrect
  get onPlayWrong
  get onOutcome

class _SentenceBuilderQuizBodyState extends State
    void initState()
    bool _isIdentityPerm(List<int> p)
    String _wordAtCell(int cellIndex)
    void _onGridTap(int cellIndex)
    Future<void> _playAudio()
    Widget build(BuildContext context)
  get _perm
  set _perm=
  get _usedCellIndices
  get _sentence
  set _sentence=
  get _tapProgress
  set _tapProgress=
  get _slots
  get _slotFromPlayer
  get _failed
  set _failed=
  get _wrongGridIndex
  set _wrongGridIndex=
  get _cellToStep
  get _completed
  set _completed=
  get _audioPlaying
  set _audioPlaying=
  get _target

## /lib/screens/quiz_templates/word_pairs_quiz_body.dart

class WordPairsQuizBody extends StatefulWidget
    State<WordPairsQuizBody> createState()
  get data
  get userLanguage
  get onPlayCorrect
  get onPlayWrong
  get onOutcome

class _WordPairsQuizBodyState extends State
    void initState()
    void _onTap(String word, bool isLeft)
    Widget _activeTile(String text, Color? bgColor, Color? textColor, bool selected, void Function()? onTap)
    Widget build(BuildContext context)
  get _match
  set _match=
  get _reverseMatch
  set _reverseMatch=
  get _activeLeft
  set _activeLeft=
  get _activeRight
  set _activeRight=
  get _matchedPairs
  get _selectedWord
  set _selectedWord=
  get _selectedIsLeft
  set _selectedIsLeft=
  get _failed
  set _failed=
  get _redLeft
  set _redLeft=
  get _redRight
  set _redRight=
  get _greenLeft
  set _greenLeft=
  get _greenRight
  set _greenRight=

## /lib/screens/quiz_templates/cloze_sequence_quiz_body.dart

class ClozeSequenceQuizBody extends StatefulWidget
    State<ClozeSequenceQuizBody> createState()
  get data
  get userLanguage
  get resolvedImagePath
  get audioAssetPath
  get resolveAudioExists
  get onPlayQuestionAudio
  get onPlayCorrect
  get onPlayWrong
  get onOutcome

class _ClozeSequenceQuizBodyState extends State
    void initState()
    Future<void> _playAudio()
    void _onTileTap(int tileIndex)
    List<InlineSpan> _buildSentenceSpans(ThemeData theme)
    Widget _buildTile(int index, ThemeData theme)
    String? _fullTranslationText()
    Widget build(BuildContext context)
  get _tokens
  set _tokens=
  get _blankIndices
  set _blankIndices=
  get _tiles
  set _tiles=
  get _filled
  set _filled=
  get _tileStates
  set _tileStates=
  get _currentBlank
  set _currentBlank=
  get _failed
  set _failed=
  get _audioPlaying
  set _audioPlaying=
  bool _isBlank(String token)

## /lib/screens/quiz_templates/appear_disappear_quiz_body.dart

class AppearDisappearQuizBody extends StatefulWidget
    State<AppearDisappearQuizBody> createState()
  get data
  get userLanguage
  get translation
  get audioAssetPath
  get resolveAudioExists
  get onPlayQuestionAudio
  get onPlayCorrect
  get onPlayWrong
  get onOutcome

class _AppearDisappearQuizBodyState extends State
    void initState()
    Future<void> _runAudioThenDisappear()
    void _onGridTap(int gridIndex)
    Widget _buildBoxRow(ThemeData theme, ColorScheme cs)
    Widget build(BuildContext context)
  get _shuffledChoices
  set _shuffledChoices=
  get _phase
  set _phase=
  get _interactionEnabled
  set _interactionEnabled=
  get _tapProgress
  set _tapProgress=
  get _interactionSlots
  get _slotFromPlayer
  get _failed
  set _failed=
  get _wrongGridIndex
  set _wrongGridIndex=
  get _correctGridIndices
  get _gridIndexToStep
  get _completed
  set _completed=
  get _sentence

## /lib/screens/quiz_templates/dialogue_completion_quiz_body.dart

class DialogueCompletionQuizBody extends StatefulWidget
    State<DialogueCompletionQuizBody> createState()
  get data
  get userLanguage
  get line1Translation
  get answerTranslation
  get audio1Path
  get audio2Path
  get resolvedImagePath
  get resolveAudioExists
  get onPlayQuestionAudio
  get onPlayCorrect
  get onPlayWrong
  get onOutcome

class _DialogueCompletionQuizBodyState extends State
    void initState()
    void didUpdateWidget(DialogueCompletionQuizBody oldWidget)
    Future<void> _primeAudio()
    Future<void> _playAudio1Manual()
    String? _combinedTranslation()
    Future<void> _onTap(int i)
    Widget build(BuildContext context)
  get _options
  set _options=
  get _locked
  set _locked=
  get _selectedIndex
  set _selectedIndex=
  get _correctIndex
  set _correctIndex=
  get _audio1Playing
  set _audio1Playing=
  get _audio2Playing
  set _audio2Playing=
  get _audio1Scheduled
  set _audio1Scheduled=
  get _audio1Ok
  set _audio1Ok=
  get _audio2Ok
  set _audio2Ok=

## /lib/screens/transitions/custom_page_routes.dart
  Route<T> scaleElasticRoute(Widget page)
  Route<T> flipScaleRoute(Widget page)
  Route<T> popFadeRoute(Widget page)
  Route<T> slideUpFadeRoute(Widget page)
  Route<T> cardFlipRoute(Widget page)

## /lib/screens/settings_panel_content.dart

class SettingsPanelContent extends ConsumerWidget
    Widget build(BuildContext context, WidgetRef ref)

class _LanguageDropdown extends StatelessWidget
    Widget build(BuildContext context)
  get value
  get codes
  get strings
  get onChanged

class _MusicSwitch extends StatelessWidget
    Widget build(BuildContext context)
  get value
  get label
  get onChanged

class _SoundFxSwitch extends StatelessWidget
    Widget build(BuildContext context)
  get value
  get label
  get onChanged

## /lib/screens/home_screen.dart

class _HomeColors extends Object
  get background
  get primary
  get onPrimary

class HomeScreen extends ConsumerStatefulWidget
    ConsumerState<HomeScreen> createState()

class _HomeScreenState extends ConsumerState
    Widget build(BuildContext context)
    Widget _buildPhoneQuizButtons(bool soundFxOn, Map<String, String> strings)
    Widget _buildTabletQuizButtons(bool soundFxOn, Map<String, String> strings)
    Widget _quizButton(String label, void Function() onTap)
    Widget _buildBottomNav(Map<String, String> strings, bool soundFxOn)
    Widget _navItem(IconData icon, String label, void Function() onTap)
    void _showSettingsPanel(Map<String, String> strings)
    void _showAchievementsPanel(Map<String, String> strings)
    void _showFriendsPanel(Map<String, String> strings)

## /lib/screens/story/story_overlay_screen.dart

class StoryOverlayScreen extends StatefulWidget
    Future<void> show(BuildContext context, StoryPageConfig page, StoryTemplateConfig? template, String languageCode, String continueLabel, String congratulationsLabel, bool isFinalPage)
    State<StoryOverlayScreen> createState()
  get page
  get template
  get languageCode
  get continueLabel
  get congratulationsLabel
  get isFinalPage

class _StoryOverlayScreenState extends State
    void initState()
    void dispose()
    Widget build(BuildContext context)
    Widget _buildTemplate(BuildContext context, double? scrollViewportHeight)
    Widget _buildAnimationOnly(BuildContext context)
  get _celebrationController
  set _celebrationController=
  get _celebrationScale
  set _celebrationScale=

## /lib/screens/story/story_templates/story_template_a.dart

class StoryTemplateA extends StatelessWidget
    Widget build(BuildContext context)
    Widget _scenePlaceholder(BuildContext context)
    Widget _characterPlaceholder(BuildContext context, double size)
    String _localizedText(StoryPageConfig page, String languageCode)
  get page
  get languageCode
  get scrollViewportHeight
  get _verticalInset

class _BubbleTailPainter extends CustomPainter
    void paint(Canvas canvas, Size size)
    bool shouldRepaint(_BubbleTailPainter oldDelegate)

## /lib/screens/story/story_templates/story_template_c.dart

class StoryTemplateC extends StatelessWidget
    Widget build(BuildContext context)
    double _innerViewportHeight(BuildContext context)
    double _maxImageHeight(double innerViewportHeight)
    Widget _placeholder(BuildContext context)
  get page
  get languageCode
  get scrollViewportHeight
  get kSectionGap
  get kEdgeInset
  get kMaxImageHeightFraction

## /lib/screens/story/story_templates/story_template_b.dart

class StoryTemplateB extends StatelessWidget
    Widget build(BuildContext context)
    String _localizedText(StoryPageConfig page, String languageCode)
  get page
  get languageCode

## /lib/screens/panel_overlay.dart

class _PanelContent extends StatelessWidget
    Widget build(BuildContext context)
  get title
  get body
  get width
  get height
  void showPanelOverlay(BuildContext context, String title, Widget body, double horizontalMarginFraction, double verticalMarginFraction, double blurSigma)

## /lib/main.dart

class MainApp extends StatelessWidget
    Widget build(BuildContext context)
  void main()

## /lib/services/achievement_service.dart

class AchievementService extends Object
    Future<AchievementState> loadState()
    Future<void> _saveState(AchievementState state)
    Future<void> recordAnswer(bool correct)
    Future<void> recordQuizCompleted(int durationSeconds)
    Future<void> saveStateForTesting(AchievementState state)
  get _instance
  get _key
  get _prefs
  set _prefs=
  get instance
  get _preferences

## /lib/services/test_data_service.dart

class TestDataService extends Object
    Future<void> seedShortQuizEndAfter3With2Stars()
    Future<bool> isShortQuizEndAfter3With2Stars()
    Future<void> _clearShortQuizDebugFlag()
    Future<void> clearTestData()
  get _instance
  get _kShortQuizAfter3With2Stars
  get instance

## /lib/services/story_progress_service.dart

class StoryProgressService extends Object
    Future<StoryProgressState> loadProgress()
    Future<void> saveProgress(StoryProgressState state)
    Future<StoryProgressState> markCompleted(StoryProgressState current, int mainLevelId, int eventId)
  get _instance
  get _storageKey
  get _prefs
  set _prefs=
  get instance
  get _preferences

## /lib/services/story_trigger_service.dart

class StoryTriggerService extends Object
    StoryPageConfig? findBeforeLevelPage(MainLevelStoryConfig? mainStory, StoryProgressState storyProgress, int mainLevelId, int currentLocalLevel, Iterable<SubLevelItem> flowSubLevels)
    StoryPageConfig? findAfterLevelPage(MainLevelStoryConfig? mainStory, StoryProgressState storyProgress, int mainLevelId, int completedLocalLevel, Iterable<SubLevelItem> flowSubLevels)
    List<StoryPageConfig> pagesReadyToMarkCompleted(MainLevelStoryConfig? mainStory, StoryProgressState storyProgress, QuizTypeProgress quizProgress, int mainLevelId, Iterable<SubLevelItem> flowSubLevels)
    Map<int, int> localLevelByOrdinal(Iterable<SubLevelItem> flowSubLevels)
    int resolveTriggerLevel(StoryPageConfig page, int mainLevelId, Iterable<SubLevelItem> flowSubLevels)
    int _resolveTriggerLevel(StoryPageConfig page, int mainLevelId, Iterable<SubLevelItem> flowSubLevels)
    Map<int, Map<int, String>> _buildMappers(Iterable<SubLevelItem> flowSubLevels)

## /lib/services/friends_config_loader.dart

class FriendAnimalDefinition extends Object
    FriendAnimalDefinition fromJson(Map<String, dynamic> json)
  get id
  get image
  get diamondCost
  get name
  get displayName
  get imageAssetPath
  Future<List<FriendAnimalDefinition>> loadFriendsConfig()

## /lib/services/profile_service.dart

class QuizTypeProfileStats extends Object
  get quizType
  get currentLevel
  get completedLevels
  get totalLevels
  get totalQuestionsAnswered
  get currentStreak
  get progressRatio

class ProfileSummary extends Object
  get lifetimeStars
  get lifetimeDiamonds
  get perQuizStats

class ProfileService extends Object
    Future<ProfileState> loadOrCreateProfile()
    Future<void> saveProfile(ProfileState profile)
    Future<List<String>> listAvatarAssets()
    Future<ProfileState> registerQuizCompletion(String quizType, int questionCount, DateTime? now)
    Future<ProfileSummary> buildSummary(ProfileState profile)
    String _generateUserId()
    String _dayKey(DateTime dateTime)
  get _instance
  get _profileKey
  get _quizTypes
  get _avatarPrefix
  get _prefs
  set _prefs=
  get instance
  get _preferences

## /lib/services/achievement_config_loader.dart

class AchievementDefinition extends Object
    AchievementDefinition fromJson(Map<String, dynamic> json)
  get id
  get type
  get title
  get description
  get icon
  get goalValue
  get trackingKey
  get showProgressBar
  get phase
  Future<List<AchievementDefinition>> loadAchievementConfig()

## /lib/services/level_config_loader.dart
  Future<LevelConfig> loadLevelConfig(String iconImageName)

## /lib/services/resolution_service.dart
  ResolutionBucket resolutionBucketFromSize(Size size)

## /lib/services/app_settings_service.dart

class AppSettingsService extends Object
    Future<String> getLanguage()
    Future<void> setLanguage(String lang)
    Future<bool> getMusicOn()
    Future<void> setMusicOn(bool value)
    Future<bool> getSoundFxOn()
    Future<void> setSoundFxOn(bool value)
  get _langKey
  get _musicKey
  get _soundFxKey
  get _defaultLanguage
  get _prefs
  set _prefs=
  get _preferences

## /lib/services/guest_animal_conversations_loader.dart
  Future<GuestAnimalConversationsConfig> loadGuestAnimalConversations()
  LanguageConversations? getForLanguage(GuestAnimalConversationsConfig config, String language)
  StepChoice? pickRandomStepConversation(LanguageConversations entry, int step)

## /lib/services/game_config_loader.dart

class GameConfig extends Object
    Future<GameConfig> load()
  get autoAdvanceDelaySeconds
  get imageQuizTimerSeconds
  get showCorrectOnWrong
  get _path

## /lib/services/friends_service.dart

class FriendsService extends Object
    Future<FriendsState> loadState()
    Future<void> saveState(FriendsState state)
  get _instance
  get _key
  get _prefs
  set _prefs=
  get instance
  get _preferences

## /lib/services/localization_loader.dart

class LocalizationLoader extends Object
    Future<Map<String, Map<String, String>>> loadAll()
    Future<List<String>> availableLanguageCodes()
    Future<String> string(String key, String? lang)
  Future<Map<String, Map<String, String>>> _load()

## /lib/services/audio_service.dart
  AudioPlayer _musicPlayerInstance()
  AudioPlayer _sfxPlayerInstance()
  AudioPlayer _ttsPlayerInstance()
  Future<void> startQuizMusic(bool musicOn)
  Future<void> stopQuizMusic()
  Future<void> playClick(bool soundFxOn)
  Future<void> playCorrect(bool soundFxOn)
  Future<void> playWrong(bool soundFxOn)
  Future<void> playQuestionAudio(String assetPath)
  Future<void> stopQuestionAudio()

## /lib/services/story_config_loader.dart
  Future<StoryConfigData> loadStoryConfig()

## /lib/services/reminder_progress_service.dart

class ReminderProgressService extends Object
    Future<ReminderProgressData> loadProgress()
    Future<void> saveProgress(ReminderProgressData progress)
    Future<ReminderProgressData> recordWrongAnswer(String questionId)
    Future<ReminderProgressData> generateReminderQuestions(int mainLevel, Map<String, int> questionCountByProgressKey)
    Future<ReminderProgressData> markReminderCompleted(int mainLevel, int reminderIndex, List<String> answeredIds)
    bool isReminderCompleted(ReminderProgressData data, int mainLevel, int reminderIndex)
    bool isReminderUnlocked(ReminderProgressData data, QuizTypeProgress quizProgress, int mainLevel, int reminderIndex, Iterable<SubLevelItem> regularFlowSubLevels)
  get _instance
  get _storageKey
  get _prefs
  set _prefs=
  get instance
  get _preferences

## /lib/services/image_asset_resolver.dart
  Future<String?> resolveQuizImageAsset(String levelKey, String imageName)

## /lib/services/quiz_flow_loader.dart

class QuizFlowData extends Object
  get subLevels
  get mainLevels
  Future<QuizFlowData> loadGameFlow()

## /lib/services/reminder_question_builder.dart

class ReminderQuestionSplit extends Object
  get reminderOneQuestionIds
  get reminderTwoQuestionIds

class ReminderQuestionBuilder extends Object
    ReminderQuestionSplit build(Map<String, int> wrongAnswerCounters, Map<String, int> questionCountByProgressKey, Random? random)

## /lib/services/quiz_progress_service.dart

class LevelProgress extends Object
    Map<String, dynamic> toJson()
    LevelProgress fromJson(Map<String, dynamic> json)
  get progressKey
  get highestStars
  get highestDiamonds
  get isCompleted

class QuizTypeProgress extends Object
    LevelProgress level(String progressKey)
    Map<String, dynamic> toJson()
    QuizTypeProgress fromJson(Map<String, dynamic> json)
  get levels
  get totalDiamonds

class QuizProgressService extends Object
    Future<QuizTypeProgress> loadProgress()
    Future<void> saveProgress(QuizTypeProgress progress)
    Future<QuizTypeProgress> recordLevelCompletion(String progressKey, int stars, int diamondsEarned)
  get _instance
  get _storageKey
  get _prefs
  set _prefs=
  get instance
  get _preferences

## /lib/services/image_quiz_level_loader.dart
  String imageQuizLevelKey(String iconImageName)
  String imageQuizLevelAssetPrefix(String levelKey)
  Future<List<String>> loadImageQuizLevelAssetPaths(String levelKey)
  bool _isDsStore(String path)
  String assetPathToBasename(String path)
  Future<List<String>> loadImageQuizLevelVocabulary(String levelKey)
  Future<List<String>> discoverGuestAnimalNames()
  Future<List<String>> discoverMonsterNames()

## /lib/services/achievement_progress_service.dart

class AchievementProgress extends Object
  get definition
  get currentValue
  get goalValue
  get isUnlocked
  get progressFraction

class AchievementProgressService extends Object
    Future<List<AchievementProgress>> computeProgress(List<AchievementDefinition> definitions, ProfileState profile)
    (int, bool, double) _evaluate(AchievementDefinition def, Map<String, int> stats, int? bestTime, int allQuizzes3Stars, int perfect10PerType)
  get _instance
  get instance

## /lib/widgets/audio_play_button.dart

class AudioPlayButton extends StatelessWidget
    Widget build(BuildContext context)
  get isPlaying
  get onPressed

## /lib/widgets/image_quiz_template2_audio_controls.dart

class ImageQuizTemplate2AudioControls extends StatefulWidget
    State<ImageQuizTemplate2AudioControls> createState()
  get assetPath
  get resolveExists
  get autoPlayDelay

class _ImageQuizTemplate2AudioControlsState extends State
    void initState()
    void didUpdateWidget(ImageQuizTemplate2AudioControls oldWidget)
    Future<void> _prime()
    Future<void> _autoPlayOnce()
    Future<void> _play(String p)
    void dispose()
    Widget build(BuildContext context)
  get _exists
  set _exists=
  get _playing
  set _playing=
  get _autoTimer
  set _autoTimer=
  get _autoFired
  set _autoFired=

## /lib/widgets/translation_reveal_button.dart

class TranslationRevealButton extends StatefulWidget
    State<TranslationRevealButton> createState()
  get translationText
  get userLanguage

class _TranslationRevealButtonState extends State
    Widget build(BuildContext context)
  get _revealed
  set _revealed=
