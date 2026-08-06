class LocaleKeys {
  LocaleKeys._();

  // Common
  static const success = 'common.success';
  static const error = 'common.error';
  static const info = 'common.info';
  static const warning = 'common.warning';
  static const close = 'common.close';
  static const cancel = 'common.cancel';
  static const confirm = 'common.confirm';
  static const delete = 'common.delete';
  static const clearAll = 'common.clearAll';
  static const copied = 'common.copied';
  static const copiedToClipboard = 'common.copiedToClipboard';
  static const noVideoPlaying = 'common.noVideoPlaying';
  static const noSegmentsToClear = 'common.noSegmentsToClear';

  // Menu
  static const menuOpenFile = 'menu.openFile';
  static const menuSubtitles = 'menu.subtitles';
  static const menuAddSubtitle = 'menu.addSubtitle';
  static const menuDisableSubtitle = 'menu.disableSubtitle';
  static const menuSubtitleSettings = 'menu.subtitleSettings';
  static const menuAudio = 'menu.audio';
  static const menuPreferences = 'menu.preferences';
  static const menuKeyboardBindings = 'menu.keyboardBindings';
  static const menuDoubleClickAction = 'menu.doubleClickAction';
  static const menuMaximizeMinimizeWindow = 'menu.maximizeMinimizeWindow';
  static const menuPlayPauseVideo = 'menu.playPauseVideo';
  static const menuSeekIntervals = 'menu.seekIntervals';
  static const menuWhenPlaylistEnds = 'menu.whenPlaylistEnds';
  static const menuShowHomeScreen = 'menu.showHomeScreen';
  static const menuShutdownApplication = 'menu.shutdownApplication';
  static const menuLanguage = 'menu.language';
  static const menuPlaylist = 'menu.playlist';
  static const menuPlaylistType = 'menu.playlistType';
  static const menuDefault = 'menu.default';
  static const menuPotPlayer = 'menu.potPlayer';
  static const menuShufflePlaylist = 'menu.shufflePlaylist';
  static const menuWhenLoadingFiles = 'menu.whenLoadingFiles';
  static const menuClearAndReplacePlaylist = 'menu.clearAndReplacePlaylist';
  static const menuAppendToExistingPlaylist = 'menu.appendToExistingPlaylist';
  static const menuBookmarks = 'menu.bookmarks';
  static const menuAddBookmark = 'menu.addBookmark';
  static const menuShowBookmarks = 'menu.showBookmarks';
  static const menuNextBookmark = 'menu.nextBookmark';
  static const menuPreviousBookmark = 'menu.previousBookmark';
  static const menuClearAllBookmarks = 'menu.clearAllBookmarks';
  static const menuAbLoopSegments = 'menu.abLoopSegments';
  static const menuAddSegmentAtCurrentPosition = 'menu.addSegmentAtCurrentPosition';
  static const menuShowSegments = 'menu.showSegments';
  static const menuStartStopABLoopPlayback = 'menu.startStopABLoopPlayback';
  static const menuNextSegment = 'menu.nextSegment';
  static const menuPreviousSegment = 'menu.previousSegment';
  static const menuImportPBF = 'menu.importPBF';
  static const menuExportPBF = 'menu.exportPBF';
  static const menuClearAllSegments = 'menu.clearAllSegments';
  static const menuAbout = 'menu.about';
  static const menuExit = 'menu.exit';
  static const menuNoAdditionalTracks = 'menu.noAdditionalTracks';

  // Dialogs
  static const dialogClearAllBookmarksTitle = 'dialog.clearAllBookmarksTitle';
  static const dialogClearAllBookmarksMessage = 'dialog.clearAllBookmarksMessage';
  static const dialogClearAllSegmentsTitle = 'dialog.clearAllSegmentsTitle';
  static const dialogClearAllSegmentsMessage = 'dialog.clearAllSegmentsMessage';
  static const dialogDeleteFileTitle = 'dialog.deleteFileTitle';
  static const dialogDeleteFileMessage = 'dialog.deleteFileMessage';

  // Snackbars
  static const snackPlaylistShuffled = 'snack.playlistShuffled';
  static const snackPlaylistShuffledMsg = 'snack.playlistShuffledMsg';
  static const snackPlaylistEndBehaviorUpdated = 'snack.playlistEndBehaviorUpdated';
  static const snackPlaylistEndHomeMsg = 'snack.playlistEndHomeMsg';
  static const snackPlaylistEndShutdownMsg = 'snack.playlistEndShutdownMsg';
  static const snackPlaylistBehaviorUpdated = 'snack.playlistBehaviorUpdated';
  static const snackPlaylistLoadClearMsg = 'snack.playlistLoadClearMsg';
  static const snackPlaylistLoadAppendMsg = 'snack.playlistLoadAppendMsg';
  static const snackBookmarkAdded = 'snack.bookmarkAdded';
  static const snackBookmarkAddedMsg = 'snack.bookmarkAddedMsg';
  static const snackFailedAddBookmark = 'snack.failedAddBookmark';
  static const snackBookmarkExists = 'snack.bookmarkExists';
  static const snackBookmarkDeleted = 'snack.bookmarkDeleted';
  static const snackBookmarkDeletedMsg = 'snack.bookmarkDeletedMsg';
  static const snackFailedDeleteBookmark = 'snack.failedDeleteBookmark';
  static const snackFailedUpdateBookmarkName = 'snack.failedUpdateBookmarkName';
  static const snackNoBookmarksAvailable = 'snack.noBookmarksAvailable';
  static const snackJumpedFirstBookmark = 'snack.jumpedFirstBookmark';
  static const snackJumpedBookmark = 'snack.jumpedBookmark';
  static const snackJumpedLastBookmark = 'snack.jumpedLastBookmark';
  static const snackJumpedToTime = 'snack.jumpedToTime';
  static const snackBookmarksCleared = 'snack.bookmarksCleared';
  static const snackBookmarksClearedMsg = 'snack.bookmarksClearedMsg';
  static const snackFailedClearBookmarks = 'snack.failedClearBookmarks';
  static const snackABLoopsLoaded = 'snack.abLoopsLoaded';
  static const snackSegmentsLoadedFrom = 'snack.segmentsLoadedFrom';
  static const snackFailedLoadPBF = 'snack.failedLoadPBF';
  static const snackSegmentAdded = 'snack.segmentAdded';
  static const snackSegmentAddedMsg = 'snack.segmentAddedMsg';
  static const snackFailedAddSegment = 'snack.failedAddSegment';
  static const snackUnableGetPosition = 'snack.unableGetPosition';
  static const snackSegmentUpdated = 'snack.segmentUpdated';
  static const snackFailedUpdateSegment = 'snack.failedUpdateSegment';
  static const snackSegmentDeleted = 'snack.segmentDeleted';
  static const snackSegmentDeletedMsg = 'snack.segmentDeletedMsg';
  static const snackFailedDeleteSegment = 'snack.failedDeleteSegment';
  static const snackSegmentsCleared = 'snack.segmentsCleared';
  static const snackSegmentsClearedMsg = 'snack.segmentsClearedMsg';
  static const snackFailedClearSegments = 'snack.failedClearSegments';
  static const snackImportSuccessful = 'snack.importSuccessful';
  static const snackImportSuccessfulMsg = 'snack.importSuccessfulMsg';
  static const snackFailedImportPBF = 'snack.failedImportPBF';
  static const snackNoSegmentsToExport = 'snack.noSegmentsToExport';
  static const snackExportABLoopsTitle = 'snack.exportABLoopsTitle';
  static const snackExportSuccessful = 'snack.exportSuccessful';
  static const snackExportSuccessfulMsg = 'snack.exportSuccessfulMsg';
  static const snackFailedExportPBF = 'snack.failedExportPBF';
  static const snackNoABLoopSegments = 'snack.noABLoopSegments';
  static const snackABLoopStarted = 'snack.abLoopStarted';
  static const snackABLoopStopped = 'snack.abLoopStopped';
  static const snackNoSegments = 'snack.noSegments';
  static const snackJumpedToSegment = 'snack.jumpedToSegment';
  static const snackAudioTrackChanged = 'snack.audioTrackChanged';
  static const snackAudioTrackChangedMsg = 'snack.audioTrackChangedMsg';
  static const snackFailedSwitchAudioTrack = 'snack.failedSwitchAudioTrack';
  static const snackSubtitleLoaded = 'snack.subtitleLoaded';
  static const snackSubtitleLoadedMsg = 'snack.subtitleLoadedMsg';
  static const snackSubtitleFormatError = 'snack.subtitleFormatError';
  static const snackFillAllFields = 'snack.fillAllFields';
  static const snackAlreadyAdded = 'snack.alreadyAdded';
  static const snackAlreadyAddedMsg = 'snack.alreadyAddedMsg';
  static const snackPlaylistCreated = 'snack.playlistCreated';
  static const snackPlaylistCreatedMsg = 'snack.playlistCreatedMsg';
  static const snackFailedDeleteFile = 'snack.failedDeleteFile';
  static const snackDeleted = 'snack.deleted';
  static const snackDeletedAndSkipped = 'snack.deletedAndSkipped';
  static const snackDeletedSuccessfully = 'snack.deletedSuccessfully';
  static const snackKeyBindingUpdated = 'snack.keyBindingUpdated';
  static const snackSwappedKeys = 'snack.swappedKeys';
  static const snackKeyAssignedTo = 'snack.keyAssignedTo';
  static const snackResetComplete = 'snack.resetComplete';
  static const snackResetCompleteMsg = 'snack.resetCompleteMsg';
  static const snackErrorLaunchingUrl = 'snack.errorLaunchingUrl';

  // Seek settings
  static const seekTitle = 'seek.title';
  static const seekResetMsg = 'seek.resetMsg';
  static const seekResetToDefaults = 'seek.resetToDefaults';
  static const seekSeekMode = 'seek.seekMode';
  static const seekRegularSeek = 'seek.regularSeek';
  static const seekBigSeek = 'seek.bigSeek';
  static const seekAdaptive = 'seek.adaptive';
  static const seekAdaptiveDesc = 'seek.adaptiveDesc';
  static const seekFixed = 'seek.fixed';
  static const seekFixedDesc = 'seek.fixedDesc';
  static const seekRangePercentSmall = 'seek.rangePercentSmall';
  static const seekRangePercentBig = 'seek.rangePercentBig';
  static const seekRangeSeconds = 'seek.rangeSeconds';

  // Subtitle settings
  static const subtitleTitle = 'subtitle.title';
  static const subtitleTabFont = 'subtitle.tabFont';
  static const subtitleTabPosition = 'subtitle.tabPosition';
  static const subtitleTabAdvanced = 'subtitle.tabAdvanced';
  static const subtitleResetMsg = 'subtitle.resetMsg';
  static const subtitleResetToDefaults = 'subtitle.resetToDefaults';
  static const subtitleFont = 'subtitle.font';
  static const subtitleSize = 'subtitle.size';
  static const subtitlePreview = 'subtitle.preview';
  static const subtitleSampleText = 'subtitle.sampleText';
  static const subtitleUp = 'subtitle.up';
  static const subtitleDown = 'subtitle.down';
  static const subtitleLeft = 'subtitle.left';
  static const subtitleRight = 'subtitle.right';
  static const subtitleVerticalHorizontal = 'subtitle.verticalHorizontal';
  static const subtitleTextAlignment = 'subtitle.textAlignment';
  static const subtitleTextColor = 'subtitle.textColor';
  static const subtitleText = 'subtitle.text';
  static const subtitleBackgroundColor = 'subtitle.backgroundColor';
  static const subtitleBackground = 'subtitle.background';
  static const subtitleOutlineWidth = 'subtitle.outlineWidth';
  static const subtitlePickColor = 'subtitle.pickColor';
  static const subtitleSelectColor = 'subtitle.selectColor';
  static const subtitleSelectColorShade = 'subtitle.selectColorShade';
  static const subtitleDone = 'subtitle.done';

  // Keyboard bindings
  static const keyboardLoading = 'keyboard.loading';
  static const keyboardTitle = 'keyboard.title';
  static const keyboardEnabled = 'keyboard.enabled';
  static const keyboardDisabled = 'keyboard.disabled';
  static const keyboardInstruction = 'keyboard.instruction';
  static const keyboardDisabledWarning = 'keyboard.disabledWarning';
  static const keyboardPressAnyKey = 'keyboard.pressAnyKey';
  static const keyboardUnassigned = 'keyboard.unassigned';
  static const keyboardHoldCtrlShift = 'keyboard.holdCtrlShift';
  static const keyboardHoldShift = 'keyboard.holdShift';
  static const keyboardHoldCtrl = 'keyboard.holdCtrl';
  static const keyboardPressKeyFor = 'keyboard.pressKeyFor';
  static const kbdPlayPause = 'kbd.playPause';
  static const kbdEnterFullscreen = 'kbd.enterFullscreen';
  static const kbdToggleMaximize = 'kbd.toggleMaximize';
  static const kbdSeekBackward = 'kbd.seekBackward';
  static const kbdSeekForward = 'kbd.seekForward';
  static const kbdBigSeekBackward = 'kbd.bigSeekBackward';
  static const kbdBigSeekForward = 'kbd.bigSeekForward';
  static const kbdVolumeUp = 'kbd.volumeUp';
  static const kbdVolumeDown = 'kbd.volumeDown';
  static const kbdToggleMute = 'kbd.toggleMute';
  static const kbdToggleSubtitles = 'kbd.toggleSubtitles';
  static const kbdExitFullscreen = 'kbd.exitFullscreen';
  static const kbdTogglePlaylist = 'kbd.togglePlaylist';
  static const kbdToggleDeveloperLog = 'kbd.toggleDeveloperLog';
  static const kbdToggleKeyboardBindings = 'kbd.toggleKeyboardBindings';
  static const kbdDecreaseSpeed = 'kbd.decreaseSpeed';
  static const kbdIncreaseSpeed = 'kbd.increaseSpeed';
  static const kbdNextTrack = 'kbd.nextTrack';
  static const kbdPreviousTrack = 'kbd.previousTrack';
  static const kbdDeleteAndSkip = 'kbd.deleteAndSkip';
  static const kbdShufflePlaylist = 'kbd.shufflePlaylist';
  static const kbdAddBookmark = 'kbd.addBookmark';
  static const kbdNextBookmark = 'kbd.nextBookmark';
  static const kbdPreviousBookmark = 'kbd.previousBookmark';
  static const kbdToggleBookmarkList = 'kbd.toggleBookmarkList';
  static const kbdAddAbLoopSegment = 'kbd.addAbLoopSegment';
  static const kbdToggleAbLoopOverlay = 'kbd.toggleAbLoopOverlay';
  static const kbdToggleAbLoopPlayback = 'kbd.toggleAbLoopPlayback';
  static const kbdPreviousAbLoopSegment = 'kbd.previousAbLoopSegment';
  static const kbdNextAbLoopSegment = 'kbd.nextAbLoopSegment';
  static const kbdExportAbLoops = 'kbd.exportAbLoops';

  // A-B Loop
  static const abLoopSegments = 'abLoop.segments';
  static const abLoopNoVideo = 'abLoop.noVideo';
  static const abLoopActive = 'abLoop.active';
  static const abLoopInactive = 'abLoop.inactive';
  static const abLoopNewSegment = 'abLoop.newSegment';
  static const abLoopStart = 'abLoop.start';
  static const abLoopStop = 'abLoop.stop';
  static const abLoopImportPBF = 'abLoop.importPBF';
  static const abLoopExportPBF = 'abLoop.exportPBF';
  static const abLoopClearAll = 'abLoop.clearAll';
  static const abLoopEmptyTitle = 'abLoop.emptyTitle';
  static const abLoopEmptyHint = 'abLoop.emptyHint';
  static const abLoopKeyNew = 'abLoop.keyNew';
  static const abLoopKeyToggle = 'abLoop.keyToggle';
  static const abLoopKeyPrev = 'abLoop.keyPrev';
  static const abLoopKeyNext = 'abLoop.keyNext';
  static const abLoopJumpToSegment = 'abLoop.jumpToSegment';
  static const abLoopEditSegment = 'abLoop.editSegment';
  static const abLoopDeleteSegment = 'abLoop.deleteSegment';

  // A-B Loop editor
  static const abLoopEditorEditTitle = 'abLoopEditor.editTitle';
  static const abLoopEditorAddTitle = 'abLoopEditor.addTitle';
  static const abLoopEditorPointA = 'abLoopEditor.pointA';
  static const abLoopEditorHhmmss = 'abLoopEditor.hhmmss';
  static const abLoopEditorUseCurrentPosition = 'abLoopEditor.useCurrentPosition';
  static const abLoopEditorDuration = 'abLoopEditor.duration';
  static const abLoopEditorDurationHint = 'abLoopEditor.durationHint';
  static const abLoopEditorSec = 'abLoopEditor.sec';
  static const abLoopEditorLoopCount = 'abLoopEditor.loopCount';
  static const abLoopEditorLoopCountHint = 'abLoopEditor.loopCountHint';
  static const abLoopEditorEnableRepeatDelay = 'abLoopEditor.enableRepeatDelay';
  static const abLoopEditorRepeatDelay = 'abLoopEditor.repeatDelay';
  static const abLoopEditorRepeatDelayHint = 'abLoopEditor.repeatDelayHint';
  static const abLoopEditorTitle = 'abLoopEditor.title';
  static const abLoopEditorTitleHint = 'abLoopEditor.titleHint';
  static const abLoopEditorUpdate = 'abLoopEditor.update';
  static const abLoopEditorAdd = 'abLoopEditor.add';
  static const abLoopEditorInvalidLoopCount = 'abLoopEditor.invalidLoopCount';
  static const abLoopEditorInvalidLoopCountMsg = 'abLoopEditor.invalidLoopCountMsg';
  static const abLoopEditorInvalidDuration = 'abLoopEditor.invalidDuration';
  static const abLoopEditorInvalidDurationMsg = 'abLoopEditor.invalidDurationMsg';
  static const abLoopEditorInvalidInput = 'abLoopEditor.invalidInput';
  static const abLoopEditorInvalidInputMsg = 'abLoopEditor.invalidInputMsg';

  // Bookmarks
  static const bookmarkTitle = 'bookmark.title';
  static const bookmarkEmptyTitle = 'bookmark.emptyTitle';
  static const bookmarkEmptyHint = 'bookmark.emptyHint';
  static const bookmarkKeyAdd = 'bookmark.keyAdd';
  static const bookmarkKeyNext = 'bookmark.keyNext';
  static const bookmarkKeyPrevious = 'bookmark.keyPrevious';
  static const bookmarkDefaultName = 'bookmark.defaultName';
  static const bookmarkEnterName = 'bookmark.enterName';
  static const bookmarkJumpToTooltip = 'bookmark.jumpToTooltip';
  static const bookmarkEditNameTooltip = 'bookmark.editNameTooltip';
  static const bookmarkDeleteTooltip = 'bookmark.deleteTooltip';
  static const bookmarkClearAllTooltip = 'bookmark.clearAllTooltip';

  // Audio
  static const audioTrack = 'audio.track';

  // Playlist
  static const playlistTitle = 'playlist.title';
  static const playlistAddNewPlaylist = 'playlist.addNewPlaylist';
  static const playlistName = 'playlist.playlistName';
  static const playlistNoFolderSelected = 'playlist.noFolderSelected';
  static const playlistBrowse = 'playlist.browse';
  static const playlistCreatePlaylist = 'playlist.createPlaylist';

  // Album
  static const albumPlay = 'album.play';
  static const albumShowInFinder = 'album.showInFinder';
  static const albumShowInExplorer = 'album.showInExplorer';
  static const albumCopyFilePath = 'album.copyFilePath';
  static const albumFilePath = 'album.filePath';
  static const albumFileProperties = 'album.fileProperties';
  static const albumRemoveFromPlaylist = 'album.removeFromPlaylist';
  static const albumDeleteFromDisk = 'album.deleteFromDisk';
  static const albumName = 'album.name';
  static const albumFormat = 'album.format';
  static const albumSize = 'album.size';
  static const albumModified = 'album.modified';
  static const albumLocation = 'album.location';
  static const albumNa = 'album.na';
  static const albumFileNotFound = 'album.fileNotFound';
  static const albumFailedGetProperties = 'album.failedGetProperties';

  // About
  static const aboutViewOnGitHub = 'about.viewOnGitHub';
  static const aboutVersion = 'about.version';

  // Developer log
  static const devLogTitle = 'devLog.title';
  static const devLogClearLogs = 'devLog.clearLogs';
}
