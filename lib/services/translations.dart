// 앱 전체 다국어 번역 테이블
// 사용법: AppTranslations.t(langCode, 'key')
// 또는: AppTranslations.tLang(langCode, 'key')

class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    // ────────────────────────────────────────────
    // 공통
    // ────────────────────────────────────────────
    'app_name': {
      'ko': 'Asome Tutor',
      'en': 'Asome Tutor',
      'ja': 'Asome Tutor',
      'zh': 'Asome Tutor',
      'es': 'Asome Tutor',
    },
    'app_slogan': {
      'ko': '합격을 향한 키워드 학습',
      'en': 'Keyword Learning to Pass',
      'ja': 'キーワード学習',
      'zh': '关键词学习',
      'es': 'Aprendizaje Clave',
    },

    // ────────────────────────────────────────────
    // 하단 네비게이션
    // ────────────────────────────────────────────
    'nav_home': {
      'ko': '홈',
      'en': 'Home',
      'ja': 'ホーム',
      'zh': '首页',
      'es': 'Inicio',
    },
    'nav_progress': {
      'ko': '진도학습',
      'en': 'Progress',
      'ja': '進度',
      'zh': '进度',
      'es': 'Progreso',
    },
    'nav_curriculum': {
      'ko': '교과서',
      'en': 'Textbook',
      'ja': '教科書',
      'zh': '课本',
      'es': 'Libro',
    },
    'nav_search': {
      'ko': '검색',
      'en': 'Search',
      'ja': '検索',
      'zh': '搜索',
      'es': 'Buscar',
    },
    'nav_consultation': {
      'ko': '상담',
      'en': 'Q&A',
      'ja': '相談',
      'zh': '咨询',
      'es': 'Consulta',
    },
    'nav_instructor': {
      'ko': '강사',
      'en': 'Tutors',
      'ja': '講師',
      'zh': '讲师',
      'es': 'Tutores',
    },

    // ────────────────────────────────────────────
    // 홈 화면 탭
    // ────────────────────────────────────────────
    'tab_recommend': {
      'ko': '추천',
      'en': 'Picks',
      'ja': 'おすすめ',
      'zh': '推荐',
      'es': 'Sugeridas',
    },
    'tab_popular': {
      'ko': '인기',
      'en': 'Popular',
      'ja': '人気',
      'zh': '热门',
      'es': 'Popular',
    },
    'tab_korean': {
      'ko': '국어',
      'en': 'Korean',
      'ja': '国語',
      'zh': '语文',
      'es': 'Coreano',
    },
    'tab_english': {
      'ko': '영어',
      'en': 'English',
      'ja': '英語',
      'zh': '英语',
      'es': 'Inglés',
    },
    'tab_math': {
      'ko': '수학',
      'en': 'Math',
      'ja': '数学',
      'zh': '数学',
      'es': 'Matemáticas',
    },
    'tab_science': {
      'ko': '과학',
      'en': 'Science',
      'ja': '理科',
      'zh': '科学',
      'es': 'Ciencias',
    },
    'tab_twice': {
      'ko': '두번설명',
      'en': 'Twice',
      'ja': '二度説明',
      'zh': '双重讲解',
      'es': 'Doble',
    },
    'tab_social': {
      'ko': '사회',
      'en': 'Social',
      'ja': '社会',
      'zh': '社会',
      'es': 'Social',
    },

    // ────────────────────────────────────────────
    // 홈 화면 콘텐츠
    // ────────────────────────────────────────────
    'section_live_lecture': {
      'ko': '📺 실제 강의 영상',
      'en': '📺 Live Lectures',
      'ja': '📺 実際の授業動画',
      'zh': '📺 实际课程视频',
      'es': '📺 Clases en Vivo',
    },
    'section_recommend': {
      'ko': '✨ 추천 강의',
      'en': '✨ Recommended',
      'ja': '✨ おすすめ',
      'zh': '✨ 推荐课程',
      'es': '✨ Recomendadas',
    },
    'section_popular': {
      'ko': '🔥 인기 강의',
      'en': '🔥 Popular',
      'ja': '🔥 人気',
      'zh': '🔥 热门课程',
      'es': '🔥 Populares',
    },
    'section_subject_lecture': {
      'ko': '📚 강의',
      'en': '📚 Lectures',
      'ja': '📚 授業',
      'zh': '📚 课程',
      'es': '📚 Clases',
    },
    'section_recent': {
      'ko': '📺 최근 본 강의',
      'en': '📺 Recently Viewed',
      'ja': '📺 最近見た授業',
      'zh': '📺 最近观看',
      'es': '📺 Vistas Recientes',
    },
    'btn_view_all': {
      'ko': '전체보기',
      'en': 'See All',
      'ja': '全て見る',
      'zh': '查看全部',
      'es': 'Ver Todo',
    },
    'btn_watch_now': {
      'ko': '지금 보기 →',
      'en': 'Watch Now →',
      'ja': '今すぐ見る →',
      'zh': '立即观看 →',
      'es': 'Ver Ahora →',
    },

    // ────────────────────────────────────────────
    // 배너
    // ────────────────────────────────────────────
    'banner_miracle_title': {
      'ko': '2분 공부의 기적',
      'en': 'The 2-Min Miracle',
      'ja': '2分学習の奇跡',
      'zh': '2分钟学习的奇迹',
      'es': 'El Milagro de 2 Min',
    },
    'banner_miracle_sub': {
      'ko': '매일 2분씩, 365일 후의 나를 상상해보세요!',
      'en': 'Just 2 mins a day. Imagine yourself in 365 days!',
      'ja': '毎日2分、365日後の自分を想像しよう！',
      'zh': '每天2分钟，想象365天后的自己！',
      'es': '¡Solo 2 min al día. Imagínate en 365 días!',
    },
    'banner_popular_title': {
      'ko': '이번 주 인기 강의',
      'en': 'Top Lecture This Week',
      'ja': '今週の人気授業',
      'zh': '本周热门课程',
      'es': 'Clase Top Esta Semana',
    },
    'banner_new_title': {
      'ko': '신규 강의 업데이트',
      'en': 'New Lecture Update',
      'ja': '新授業アップデート',
      'zh': '新课程更新',
      'es': 'Nueva Clase',
    },
    'banner_new_sub': {
      'ko': '고등 수학 삼각함수 시리즈 오픈!',
      'en': 'Trigonometry Series Now Open!',
      'ja': '三角関数シリーズ公開！',
      'zh': '高中数学三角函数系列开放！',
      'es': '¡Serie Trigonometría Abierta!',
    },

    // ────────────────────────────────────────────
    // 학습 통계
    // ────────────────────────────────────────────
    'stat_streak': {
      'ko': '연속 학습',
      'en': 'Day Streak',
      'ja': '連続学習',
      'zh': '连续学习',
      'es': 'Racha',
    },
    'stat_today': {
      'ko': '오늘 학습',
      'en': "Today's Study",
      'ja': '今日の学習',
      'zh': '今日学习',
      'es': 'Hoy',
    },
    'stat_completed': {
      'ko': '완료 강의',
      'en': 'Completed',
      'ja': '完了授業',
      'zh': '已完成',
      'es': 'Completadas',
    },
    'unit_day': {
      'ko': '일',
      'en': ' days',
      'ja': '日',
      'zh': '天',
      'es': ' días',
    },
    'unit_min': {
      'ko': '분',
      'en': ' min',
      'ja': '分',
      'zh': '分',
      'es': ' min',
    },
    'unit_count': {
      'ko': '개',
      'en': '',
      'ja': '個',
      'zh': '个',
      'es': '',
    },

    // ────────────────────────────────────────────
    // 강의 플레이어
    // ────────────────────────────────────────────
    'player_play_on_youtube': {
      'ko': 'YouTube에서 재생',
      'en': 'Play on YouTube',
      'ja': 'YouTubeで再生',
      'zh': '在YouTube播放',
      'es': 'Ver en YouTube',
    },
    'player_tap_hint': {
      'ko': '탭하면 YouTube 앱이 열립니다',
      'en': 'Tap to open YouTube app',
      'ja': 'タップするとYouTubeアプリが開きます',
      'zh': '点击打开YouTube应用',
      'es': 'Toca para abrir YouTube',
    },
    'player_open_youtube': {
      'ko': 'YouTube',
      'en': 'YouTube',
      'ja': 'YouTube',
      'zh': 'YouTube',
      'es': 'YouTube',
    },
    'player_fullscreen': {
      'ko': '전체화면',
      'en': 'Fullscreen',
      'ja': '全画面',
      'zh': '全屏',
      'es': 'Pantalla Completa',
    },
    'player_exit_fullscreen': {
      'ko': '전체화면 해제',
      'en': 'Exit Fullscreen',
      'ja': '全画面解除',
      'zh': '退出全屏',
      'es': 'Salir Pantalla Completa',
    },
    'player_landscape': {
      'ko': '가로보기',
      'en': 'Landscape',
      'ja': '横表示',
      'zh': '横屏',
      'es': 'Horizontal',
    },
    'player_portrait': {
      'ko': '전체보기',
      'en': 'Full View',
      'ja': '全体表示',
      'zh': '全部显示',
      'es': 'Vista Completa',
    },
    'player_tab_note': {
      'ko': '교안',
      'en': 'Notes',
      'ja': '教案',
      'zh': '教案',
      'es': 'Notas',
    },
    'player_tab_qa': {
      'ko': 'Q&A',
      'en': 'Q&A',
      'ja': 'Q&A',
      'zh': 'Q&A',
      'es': 'Q&A',
    },
    'player_tab_playlist': {
      'ko': '강의목록',
      'en': 'Playlist',
      'ja': '授業リスト',
      'zh': '课程列表',
      'es': 'Lista',
    },
    'player_tab_info': {
      'ko': '강의정보',
      'en': 'Info',
      'ja': '授業情報',
      'zh': '课程信息',
      'es': 'Info',
    },

    // ────────────────────────────────────────────
    // 알림
    // ────────────────────────────────────────────
    'notification_title': {
      'ko': '알림',
      'en': 'Notifications',
      'ja': '通知',
      'zh': '通知',
      'es': 'Notificaciones',
    },
    'notif_new_lecture': {
      'ko': '신규 강의',
      'en': 'New Lecture',
      'ja': '新授業',
      'zh': '新课程',
      'es': 'Nueva Clase',
    },
    'notif_answer': {
      'ko': '상담 답변',
      'en': 'Q&A Reply',
      'ja': '相談返答',
      'zh': '咨询回复',
      'es': 'Respuesta Q&A',
    },
    'notif_goal': {
      'ko': '학습 알림',
      'en': 'Study Alert',
      'ja': '学習通知',
      'zh': '学习通知',
      'es': 'Alerta Estudio',
    },

    // ────────────────────────────────────────────
    // 검색
    // ────────────────────────────────────────────
    'search_hint': {
      'ko': '강의, 강사, 과목 검색',
      'en': 'Search lectures, tutors, subjects',
      'ja': '授業・講師・科目を検索',
      'zh': '搜索课程、讲师、科目',
      'es': 'Buscar clases, tutores, materias',
    },
    'search_recent': {
      'ko': '최근 검색어',
      'en': 'Recent Searches',
      'ja': '最近の検索',
      'zh': '最近搜索',
      'es': 'Búsquedas Recientes',
    },
    'search_popular': {
      'ko': '인기 검색어',
      'en': 'Popular Searches',
      'ja': '人気の検索',
      'zh': '热门搜索',
      'es': 'Búsquedas Populares',
    },
    'search_delete_all': {
      'ko': '전체 삭제',
      'en': 'Clear All',
      'ja': '全て削除',
      'zh': '清除全部',
      'es': 'Borrar Todo',
    },
    'search_no_result': {
      'ko': '검색 결과가 없습니다',
      'en': 'No results found',
      'ja': '検索結果がありません',
      'zh': '没有搜索结果',
      'es': 'Sin resultados',
    },

    // ────────────────────────────────────────────
    // 과목명
    // ────────────────────────────────────────────
    'subject_korean': {
      'ko': '국어',
      'en': 'Korean',
      'ja': '国語',
      'zh': '语文',
      'es': 'Coreano',
    },
    'subject_english': {
      'ko': '영어',
      'en': 'English',
      'ja': '英語',
      'zh': '英语',
      'es': 'Inglés',
    },
    'subject_math': {
      'ko': '수학',
      'en': 'Math',
      'ja': '数学',
      'zh': '数学',
      'es': 'Matemáticas',
    },
    'subject_science': {
      'ko': '과학',
      'en': 'Science',
      'ja': '理科',
      'zh': '科学',
      'es': 'Ciencias',
    },
    'subject_social': {
      'ko': '사회',
      'en': 'Social Studies',
      'ja': '社会',
      'zh': '社会',
      'es': 'Estudios Sociales',
    },

    // ────────────────────────────────────────────
    // 학년
    // ────────────────────────────────────────────
    'grade_elementary': {
      'ko': '초등',
      'en': 'Elementary',
      'ja': '小学',
      'zh': '小学',
      'es': 'Primaria',
    },
    'grade_pre_middle': {
      'ko': '예비중',
      'en': 'Pre-Middle',
      'ja': '中学準備',
      'zh': '初中预备',
      'es': 'Pre-Secundaria',
    },
    'grade_middle': {
      'ko': '중등',
      'en': 'Middle',
      'ja': '中学',
      'zh': '初中',
      'es': 'Secundaria',
    },
    'grade_high': {
      'ko': '고등',
      'en': 'High School',
      'ja': '高校',
      'zh': '高中',
      'es': 'Preparatoria',
    },

    // ────────────────────────────────────────────
    // 강사 화면
    // ────────────────────────────────────────────
    'instructor_title': {
      'ko': '강사',
      'en': 'Tutors',
      'ja': '講師',
      'zh': '讲师',
      'es': 'Tutores',
    },
    'instructor_lecture_count': {
      'ko': '강의',
      'en': 'Lectures',
      'ja': '授業',
      'zh': '课程',
      'es': 'Clases',
    },
    'instructor_followers': {
      'ko': '팔로워',
      'en': 'Followers',
      'ja': 'フォロワー',
      'zh': '粉丝',
      'es': 'Seguidores',
    },
    'instructor_follow': {
      'ko': '팔로우',
      'en': 'Follow',
      'ja': 'フォロー',
      'zh': '关注',
      'es': 'Seguir',
    },

    // ────────────────────────────────────────────
    // 진도 화면
    // ────────────────────────────────────────────
    'progress_title': {
      'ko': '진도학습',
      'en': 'My Progress',
      'ja': '進度学習',
      'zh': '学习进度',
      'es': 'Mi Progreso',
    },
    'progress_total_study': {
      'ko': '총 학습시간',
      'en': 'Total Study Time',
      'ja': '総学習時間',
      'zh': '总学习时间',
      'es': 'Tiempo Total',
    },
    'progress_completed_lectures': {
      'ko': '완료 강의수',
      'en': 'Completed Lectures',
      'ja': '完了授業数',
      'zh': '已完成课程',
      'es': 'Clases Completadas',
    },
    'progress_achievement_rate': {
      'ko': '달성률',
      'en': 'Achievement',
      'ja': '達成率',
      'zh': '达成率',
      'es': 'Logro',
    },

    // ────────────────────────────────────────────
    // 상담 화면
    // ────────────────────────────────────────────
    'consultation_title': {
      'ko': '상담',
      'en': 'Q&A',
      'ja': '相談',
      'zh': '咨询',
      'es': 'Consulta',
    },
    'consultation_answered': {
      'ko': '답변완료',
      'en': 'Answered',
      'ja': '回答済',
      'zh': '已回答',
      'es': 'Respondido',
    },
    'consultation_pending': {
      'ko': '답변대기',
      'en': 'Pending',
      'ja': '回答待ち',
      'zh': '等待回答',
      'es': 'Pendiente',
    },
    'consultation_ask': {
      'ko': '질문하기',
      'en': 'Ask Question',
      'ja': '質問する',
      'zh': '提问',
      'es': 'Hacer Pregunta',
    },

    // ────────────────────────────────────────────
    // 프로필 / 설정
    // ────────────────────────────────────────────
    'profile_title': {
      'ko': '내 정보',
      'en': 'My Profile',
      'ja': 'マイプロフィール',
      'zh': '我的信息',
      'es': 'Mi Perfil',
    },
    'settings_title': {
      'ko': '설정',
      'en': 'Settings',
      'ja': '設定',
      'zh': '设置',
      'es': 'Configuración',
    },
    'settings_language': {
      'ko': '언어 설정',
      'en': 'Language',
      'ja': '言語設定',
      'zh': '语言设置',
      'es': 'Idioma',
    },
    'settings_notification': {
      'ko': '알림 설정',
      'en': 'Notifications',
      'ja': '通知設定',
      'zh': '通知设置',
      'es': 'Notificaciones',
    },
    'settings_logout': {
      'ko': '로그아웃',
      'en': 'Logout',
      'ja': 'ログアウト',
      'zh': '退出登录',
      'es': 'Cerrar Sesión',
    },
    'premium_badge': {
      'ko': '프리미엄',
      'en': 'Premium',
      'ja': 'プレミアム',
      'zh': '高级会员',
      'es': 'Premium',
    },
    'days_remaining': {
      'ko': '일 남음',
      'en': ' days left',
      'ja': '日残り',
      'zh': '天剩余',
      'es': ' días restantes',
    },

    // ────────────────────────────────────────────
    // 기타
    // ────────────────────────────────────────────
    'loading': {
      'ko': '로딩 중...',
      'en': 'Loading...',
      'ja': '読み込み中...',
      'zh': '加载中...',
      'es': 'Cargando...',
    },
    'error_retry': {
      'ko': '다시 시도',
      'en': 'Retry',
      'ja': 'もう一度',
      'zh': '重试',
      'es': 'Reintentar',
    },
    'cancel': {
      'ko': '취소',
      'en': 'Cancel',
      'ja': 'キャンセル',
      'zh': '取消',
      'es': 'Cancelar',
    },
    'confirm': {
      'ko': '확인',
      'en': 'Confirm',
      'ja': '確認',
      'zh': '确认',
      'es': 'Confirmar',
    },
    'storyboard_tooltip': {
      'ko': '스토리보드',
      'en': 'Storyboard',
      'ja': 'ストーリーボード',
      'zh': '故事板',
      'es': 'Guión',
    },
    'notification_tooltip': {
      'ko': '알림',
      'en': 'Notifications',
      'ja': '通知',
      'zh': '通知',
      'es': 'Notificaciones',
    },
    'menu_tooltip': {
      'ko': '메뉴',
      'en': 'Menu',
      'ja': 'メニュー',
      'zh': '菜单',
      'es': 'Menú',
    },
    'landscape_guide_title': {
      'ko': '가로 모드 안내',
      'en': 'Landscape Mode Guide',
      'ja': '横モード案内',
      'zh': '横屏模式说明',
      'es': 'Guía Modo Horizontal',
    },
    'landscape_guide_body': {
      'ko': '핸드폰을 가로로 돌리면\n왼쪽에 영상, 오른쪽에 강의 정보가 함께 보입니다.',
      'en': 'Rotate your phone sideways\nto see the video and lecture info side by side.',
      'ja': '横に回転すると\n左に動画、右に授業情報が表示されます。',
      'zh': '将手机横置\n左侧显示视频，右侧显示课程信息。',
      'es': 'Gira el teléfono horizontalmente\npara ver el video e info juntos.',
    },

    // ────────────────────────────────────────────
    // 검색 화면 추가
    // ────────────────────────────────────────────
    'search_cancel': {
      'ko': '취소', 'en': 'Cancel', 'ja': 'キャンセル', 'zh': '取消', 'es': 'Cancelar',
    },
    'search_hint2': {
      'ko': '강의명, 강사, 해시태그 검색',
      'en': 'Lecture, tutor, hashtag search',
      'ja': '授業名・講師・ハッシュタグ検索',
      'zh': '课程名、讲师、标签搜索',
      'es': 'Buscar clase, tutor, etiqueta',
    },
    'search_popular_tab': {
      'ko': '인기 검색어', 'en': 'Popular', 'ja': '人気検索', 'zh': '热门搜索', 'es': 'Popular',
    },
    'search_recent_tab': {
      'ko': '최근 검색어', 'en': 'Recent', 'ja': '最近の検索', 'zh': '最近搜索', 'es': 'Reciente',
    },
    'search_recent_label': {
      'ko': '최근 검색', 'en': 'Recent', 'ja': '最近', 'zh': '最近', 'es': 'Reciente',
    },
    'search_clear_all': {
      'ko': '전체 삭제', 'en': 'Clear All', 'ja': '全削除', 'zh': '清除全部', 'es': 'Borrar Todo',
    },
    'search_no_history': {
      'ko': '검색 기록이 없어요', 'en': 'No search history', 'ja': '検索履歴なし', 'zh': '无搜索记录', 'es': 'Sin historial',
    },
    'search_browse_subject': {
      'ko': '과목별 탐색', 'en': 'Browse by Subject', 'ja': '科目別検索', 'zh': '按科目浏览', 'es': 'Por Materia',
    },
    'search_sort': {
      'ko': '정렬 기준', 'en': 'Sort By', 'ja': '並び順', 'zh': '排序', 'es': 'Ordenar',
    },
    'search_result_count': {
      'ko': '검색 결과', 'en': 'results', 'ja': '件', 'zh': '条结果', 'es': 'resultados',
    },
    'search_no_result2': {
      'ko': '검색 결과가 없습니다', 'en': 'No results found', 'ja': '結果なし', 'zh': '无结果', 'es': 'Sin resultados',
    },
    'search_try_other': {
      'ko': '다른 검색어를 입력해보세요', 'en': 'Try a different keyword', 'ja': '別のキーワードを試してください', 'zh': '请尝试其他关键词', 'es': 'Prueba otro término',
    },
    'sort_relevant': {
      'ko': '관련순', 'en': 'Relevant', 'ja': '関連順', 'zh': '相关', 'es': 'Relevante',
    },
    'sort_newest': {
      'ko': '최신순', 'en': 'Newest', 'ja': '新着順', 'zh': '最新', 'es': 'Reciente',
    },
    'sort_rating': {
      'ko': '평점순', 'en': 'Top Rated', 'ja': '評価順', 'zh': '评分', 'es': 'Mejor valorado',
    },
    'sort_views': {
      'ko': '조회순', 'en': 'Most Viewed', 'ja': '閲覧順', 'zh': '最多观看', 'es': 'Más visto',
    },
    'grade_all': {
      'ko': '전체', 'en': 'All', 'ja': 'すべて', 'zh': '全部', 'es': 'Todos',
    },
    'subject_all': {
      'ko': '전체', 'en': 'All', 'ja': 'すべて', 'zh': '全部', 'es': 'Todos',
    },
    'subject_other': {
      'ko': '기타', 'en': 'Other', 'ja': 'その他', 'zh': '其他', 'es': 'Otros',
    },

    // ────────────────────────────────────────────
    // 진도 화면
    // ────────────────────────────────────────────
    'filter_grade': {
      'ko': '학제', 'en': 'Level', 'ja': '学制', 'zh': '学制', 'es': 'Nivel',
    },
    'overall_progress': {
      'ko': '전체 진도율', 'en': 'Overall Progress', 'ja': '全体進捗率', 'zh': '总体进度', 'es': 'Progreso Total',
    },
    'unit_progress': {
      'ko': '단원 진도', 'en': 'Unit Progress', 'ja': 'ユニット進捗', 'zh': '单元进度', 'es': 'Progreso Unidad',
    },
    'lectures_label': {
      'ko': '강의', 'en': 'lectures', 'ja': '授業', 'zh': '节课', 'es': 'clases',
    },
    'completed_label': {
      'ko': '완료', 'en': 'done', 'ja': '完了', 'zh': '完成', 'es': 'hecho',
    },
    'watch_lecture': {
      'ko': '강의 보기', 'en': 'Watch', 'ja': '見る', 'zh': '观看', 'es': 'Ver',
    },

    // ────────────────────────────────────────────
    // 상담 화면
    // ────────────────────────────────────────────
    'consultation_expert': {
      'ko': '내 상담', 'en': 'My Q&A', 'ja': '相談履歴', 'zh': '我的咨询', 'es': 'Mi Consulta',
    },
    'sort_latest': {
      'ko': '최신순', 'en': 'Latest', 'ja': '最新順', 'zh': '最新', 'es': 'Reciente',
    },
    'sort_views2': {
      'ko': '조회순', 'en': 'Most Viewed', 'ja': '閲覧順', 'zh': '最多观看', 'es': 'Más visto',
    },
    'sort_answered': {
      'ko': '답변완료순', 'en': 'Answered', 'ja': '回答済順', 'zh': '已回答', 'es': 'Respondido',
    },
    'answer_complete': {
      'ko': '답변완료', 'en': 'Answered', 'ja': '回答済', 'zh': '已回答', 'es': 'Respondido',
    },
    'answer_pending': {
      'ko': '답변대기', 'en': 'Pending', 'ja': '回答待ち', 'zh': '等待回答', 'es': 'Pendiente',
    },
    'ask_question': {
      'ko': '질문하기', 'en': 'Ask', 'ja': '質問する', 'zh': '提问', 'es': 'Preguntar',
    },
    'total_questions': {
      'ko': '총 질문', 'en': 'Total Q', 'ja': '総質問', 'zh': '总问题', 'es': 'Total P',
    },
    'answered_count': {
      'ko': '답변완료', 'en': 'Answered', 'ja': '回答済', 'zh': '已回答', 'es': 'Respondidas',
    },
    'response_rate': {
      'ko': '답변률', 'en': 'Rate', 'ja': '回答率', 'zh': '回答率', 'es': 'Tasa',
    },
    'views_label': {
      'ko': '조회', 'en': 'views', 'ja': '閲覧', 'zh': '浏览', 'es': 'vistas',
    },
    'write_question': {
      'ko': '질문 작성', 'en': 'Write Question', 'ja': '質問を書く', 'zh': '写问题', 'es': 'Escribir',
    },
    'write_title_hint': {
      'ko': '제목을 입력하세요', 'en': 'Enter title', 'ja': 'タイトルを入力', 'zh': '输入标题', 'es': 'Título',
    },
    'write_content_hint': {
      'ko': '질문 내용을 자세히 입력해주세요', 'en': 'Describe your question', 'ja': '質問を詳しく', 'zh': '详细描述问题', 'es': 'Describe tu pregunta',
    },
    'submit': {
      'ko': '등록', 'en': 'Submit', 'ja': '登録', 'zh': '提交', 'es': 'Enviar',
    },

    // ────────────────────────────────────────────
    // 강사 화면
    // ────────────────────────────────────────────
    'instructor_by': {
      'ko': '강사별 강의', 'en': 'Lectures by Tutor', 'ja': '講師別授業', 'zh': '按讲师课程', 'es': 'Por Tutor',
    },
    'series': {
      'ko': '시리즈', 'en': 'Series', 'ja': 'シリーズ', 'zh': '系列', 'es': 'Serie',
    },

    // ────────────────────────────────────────────
    // 프로필 드로어
    // ────────────────────────────────────────────
    'my_activity': {
      'ko': '나의 활동', 'en': 'My Activity', 'ja': '活動', 'zh': '我的活动', 'es': 'Mi Actividad',
    },
    'recent_lectures': {
      'ko': '최근 본 강의', 'en': 'Recent Lectures', 'ja': '最近見た授業', 'zh': '最近观看', 'es': 'Recientes',
    },
    'my_notes': {
      'ko': '내 노트', 'en': 'My Notes', 'ja': 'ノート', 'zh': '我的笔记', 'es': 'Notas',
    },
    'my_qa': {
      'ko': '나의 Q&A', 'en': 'My Q&A', 'ja': 'Q&A', 'zh': '我的Q&A', 'es': 'Mi Q&A',
    },
    'expert_consult': {
      'ko': '내 상담', 'en': 'My Q&A', 'ja': '相談履歴', 'zh': '我的咨询', 'es': 'Mi Consulta',
    },
    'my_consult': {
      'ko': '내 상담', 'en': 'My Q&A', 'ja': '相談履歴', 'zh': '我的咨询', 'es': 'Mi Consulta',
    },
    'favorites': {
      'ko': '즐겨찾기', 'en': 'Favorites', 'ja': 'お気に入り', 'zh': '收藏', 'es': 'Favoritos',
    },
    'study_manage': {
      'ko': '학습 관리', 'en': 'Study Manage', 'ja': '学習管理', 'zh': '学习管理', 'es': 'Gestión',
    },
    'my_schedule': {
      'ko': '나의 일정', 'en': 'My Schedule', 'ja': 'スケジュール', 'zh': '我的日程', 'es': 'Horario',
    },
    'textbook_progress': {
      'ko': '교과서 진도학습', 'en': 'Textbook Progress', 'ja': '教科書進度', 'zh': '教科书进度', 'es': 'Progreso',
    },
    'study_stats': {
      'ko': '학습 통계', 'en': 'Study Stats', 'ja': '学習統計', 'zh': '学习统计', 'es': 'Estadísticas',
    },
    'subscription': {
      'ko': '이용권', 'en': 'Subscription', 'ja': '利用券', 'zh': '订阅', 'es': 'Suscripción',
    },
    'extend_period': {
      'ko': '사용 기간 연장', 'en': 'Extend Period', 'ja': '期間延長', 'zh': '延长时间', 'es': 'Extender',
    },
    'payment_history': {
      'ko': '결제 내역', 'en': 'Payment History', 'ja': '決済履歴', 'zh': '付款记录', 'es': 'Pagos',
    },
    'app_info': {
      'ko': 'Asome Tutor', 'en': 'Asome Tutor', 'ja': 'Asome Tutor', 'zh': 'Asome Tutor', 'es': 'Asome Tutor',
    },
    'about_app': {
      'ko': 'Asome Tutor란?', 'en': 'About Asome Tutor', 'ja': 'Asome Tutorとは', 'zh': '关于Asome Tutor', 'es': 'Sobre Asome Tutor',
    },
    'storyboard': {
      'ko': '스토리보드 뷰어', 'en': 'Storyboard', 'ja': 'ストーリーボード', 'zh': '故事板', 'es': 'Guión',
    },
    'notice': {
      'ko': '공지사항', 'en': 'Notice', 'ja': 'お知らせ', 'zh': '公告', 'es': 'Avisos',
    },
    'support': {
      'ko': '고객센터', 'en': 'Support', 'ja': 'サポート', 'zh': '客服', 'es': 'Soporte',
    },
    'settings': {
      'ko': '설정', 'en': 'Settings', 'ja': '設定', 'zh': '设置', 'es': 'Ajustes',
    },
    'app_settings': {
      'ko': '앱 설정', 'en': 'App Settings', 'ja': 'アプリ設定', 'zh': '应用设置', 'es': 'Configuración',
    },
    'terms': {
      'ko': '이용약관', 'en': 'Terms of Use', 'ja': '利用規約', 'zh': '使用条款', 'es': 'Términos',
    },
    'privacy': {
      'ko': '개인정보처리방침', 'en': 'Privacy Policy', 'ja': 'プライバシー', 'zh': '隐私政策', 'es': 'Privacidad',
    },
    'version': {
      'ko': '버전', 'en': 'Version', 'ja': 'バージョン', 'zh': '版本', 'es': 'Versión',
    },
    'logout': {
      'ko': '로그아웃', 'en': 'Logout', 'ja': 'ログアウト', 'zh': '退出', 'es': 'Salir',
    },
    'logout_confirm': {
      'ko': '정말 로그아웃 하시겠습니까?', 'en': 'Are you sure you want to logout?',
      'ja': 'ログアウトしますか？', 'zh': '确认退出？', 'es': '¿Cerrar sesión?',
    },
    'edit_profile': {
      'ko': '프로필 수정', 'en': 'Edit Profile', 'ja': 'プロフィール編集', 'zh': '编辑资料', 'es': 'Editar Perfil',
    },
    'premium_label': {
      'ko': '프리미엄', 'en': 'Premium', 'ja': 'プレミアム', 'zh': '高级', 'es': 'Premium',
    },
    'regular_label': {
      'ko': '일반', 'en': 'Regular', 'ja': '一般', 'zh': '普通', 'es': 'Regular',
    },
    'days_left': {
      'ko': '일 남음', 'en': ' days left', 'ja': '日残り', 'zh': '天剩余', 'es': ' días',
    },
    'no_subscription': {
      'ko': '이용권이 없습니다', 'en': 'No subscription', 'ja': '利用券なし', 'zh': '无订阅', 'es': 'Sin suscripción',
    },
    'extend_btn': {
      'ko': '기간 연장', 'en': 'Extend', 'ja': '延長', 'zh': '延长', 'es': 'Extender',
    },
    'buy_btn': {
      'ko': '이용권 구매', 'en': 'Buy Now', 'ja': '購入', 'zh': '购买', 'es': 'Comprar',
    },
    'my_study_stats': {
      'ko': '나의 학습 통계', 'en': 'My Study Stats', 'ja': '学習統計', 'zh': '我的学习统计', 'es': 'Estadísticas',
    },
    'streak_label': {
      'ko': '🔥 연속 학습', 'en': '🔥 Day Streak', 'ja': '🔥 連続学習', 'zh': '🔥 连续学习', 'es': '🔥 Racha',
    },
    'today_label': {
      'ko': '⏱️ 오늘 학습', 'en': '⏱️ Today', 'ja': '⏱️ 今日', 'zh': '⏱️ 今日', 'es': '⏱️ Hoy',
    },
    'total_label': {
      'ko': '📚 총 학습', 'en': '📚 Total', 'ja': '📚 合計', 'zh': '📚 总计', 'es': '📚 Total',
    },
    'completed_lec': {
      'ko': '✅ 완료 강의', 'en': '✅ Completed', 'ja': '✅ 完了授業', 'zh': '✅ 已完成', 'es': '✅ Completadas',
    },
    'bookmarks': {
      'ko': '🔖 즐겨찾기', 'en': '🔖 Bookmarks', 'ja': '🔖 お気に入り', 'zh': '🔖 收藏', 'es': '🔖 Favoritos',
    },
    'save_changes': {
      'ko': '수정 완료', 'en': 'Save Changes', 'ja': '変更保存', 'zh': '保存更改', 'es': 'Guardar',
    },
    'profile_saved': {
      'ko': '프로필이 수정되었습니다!', 'en': 'Profile updated!', 'ja': 'プロフィール更新！', 'zh': '资料已更新！', 'es': '¡Perfil actualizado!',
    },
    'id_label': {
      'ko': 'ID', 'en': 'ID', 'ja': 'ID', 'zh': 'ID', 'es': 'ID',
    },
    'id_cant_change': {
      'ko': '아이디는 변경할 수 없습니다', 'en': 'ID cannot be changed', 'ja': 'IDは変更できません', 'zh': 'ID不可更改', 'es': 'ID no editable',
    },
    'nickname_label': {
      'ko': '닉네임', 'en': 'Nickname', 'ja': 'ニックネーム', 'zh': '昵称', 'es': 'Apodo',
    },
    'email_label': {
      'ko': '이메일', 'en': 'Email', 'ja': 'メール', 'zh': '邮箱', 'es': 'Correo',
    },
    'subscription_label': {
      'ko': '이용권', 'en': 'Subscription', 'ja': '利用券', 'zh': '订阅', 'es': 'Suscripción',
    },
    'subscription_days': {
      'ko': '이용권', 'en': 'Subscription', 'ja': '利用券', 'zh': '订阅', 'es': 'Suscripción',
    },

    // ────────────────────────────────────────────
    // 강의 플레이어 탭
    // ────────────────────────────────────────────
    'tab_note': {
      'ko': '교안', 'en': 'Notes', 'ja': '教案', 'zh': '教案', 'es': 'Notas',
    },
    'tab_qa': {
      'ko': 'Q&A', 'en': 'Q&A', 'ja': 'Q&A', 'zh': 'Q&A', 'es': 'Q&A',
    },
    'tab_playlist': {
      'ko': '강의목록', 'en': 'Playlist', 'ja': '授業リスト', 'zh': '课程列表', 'es': 'Lista',
    },
    'tab_info': {
      'ko': '강의정보', 'en': 'Info', 'ja': '授業情報', 'zh': '课程信息', 'es': 'Info',
    },
    'lecture_info': {
      'ko': '강의 정보', 'en': 'Lecture Info', 'ja': '授業情報', 'zh': '课程信息', 'es': 'Info Clase',
    },
    'instructor_label': {
      'ko': '강사', 'en': 'Tutor', 'ja': '講師', 'zh': '讲师', 'es': 'Tutor',
    },
    'subject_label': {
      'ko': '과목', 'en': 'Subject', 'ja': '科目', 'zh': '科目', 'es': 'Materia',
    },
    'duration_label': {
      'ko': '강의 시간', 'en': 'Duration', 'ja': '授業時間', 'zh': '时长', 'es': 'Duración',
    },
    'rating_label': {
      'ko': '평점', 'en': 'Rating', 'ja': '評価', 'zh': '评分', 'es': 'Calificación',
    },
    'views_count': {
      'ko': '조회수', 'en': 'Views', 'ja': '閲覧数', 'zh': '浏览量', 'es': 'Vistas',
    },
    'add_favorite': {
      'ko': '즐겨찾기 추가', 'en': 'Add Favorite', 'ja': 'お気に入り追加', 'zh': '添加收藏', 'es': 'Favorito',
    },
    'remove_favorite': {
      'ko': '즐겨찾기 삭제', 'en': 'Remove Favorite', 'ja': 'お気に入り削除', 'zh': '取消收藏', 'es': 'Quitar',
    },
    'related_lectures': {
      'ko': '관련 강의', 'en': 'Related Lectures', 'ja': '関連授業', 'zh': '相关课程', 'es': 'Relacionadas',
    },
    'no_related': {
      'ko': '관련 강의가 없습니다', 'en': 'No related lectures', 'ja': '関連授業なし', 'zh': '无相关课程', 'es': 'Sin relacionadas',
    },
    'description_label': {
      'ko': '강의 설명', 'en': 'Description', 'ja': '授業説明', 'zh': '课程描述', 'es': 'Descripción',
    },
    'hashtags_label': {
      'ko': '해시태그', 'en': 'Hashtags', 'ja': 'ハッシュタグ', 'zh': '标签', 'es': 'Etiquetas',
    },
    'series_label': {
      'ko': '시리즈', 'en': 'Series', 'ja': 'シリーズ', 'zh': '系列', 'es': 'Serie',
    },
    'rotation_guide': {
      'ko': '가로 모드 안내', 'en': 'Landscape Guide', 'ja': '横モード案内', 'zh': '横屏说明', 'es': 'Modo Horizontal',
    },
    'close': {
      'ko': '닫기', 'en': 'Close', 'ja': '閉じる', 'zh': '关闭', 'es': 'Cerrar',
    },
    'page_label': {
      'ko': '페이지', 'en': 'Page', 'ja': 'ページ', 'zh': '页', 'es': 'Página',
    },
    'drawing_mode': {
      'ko': '필기', 'en': 'Draw', 'ja': '書く', 'zh': '书写', 'es': 'Dibujar',
    },
    'eraser': {
      'ko': '지우개', 'en': 'Eraser', 'ja': '消しゴム', 'zh': '橡皮', 'es': 'Borrador',
    },
    'note_hint': {
      'ko': '메모를 입력하세요...', 'en': 'Enter notes...', 'ja': 'メモを入力...', 'zh': '输入笔记...', 'es': 'Escribir nota...',
    },
    'save_note': {
      'ko': '저장', 'en': 'Save', 'ja': '保存', 'zh': '保存', 'es': 'Guardar',
    },
    'rate_lecture': {
      'ko': '강의 평가', 'en': 'Rate Lecture', 'ja': '授業評価', 'zh': '评价课程', 'es': 'Calificar',
    },
    'no_lectures': {
      'ko': '강의가 없습니다', 'en': 'No lectures', 'ja': '授業なし', 'zh': '无课程', 'es': 'Sin clases',
    },

    // ────────────────────────────────────────────
    // 나의 활동 화면
    // ────────────────────────────────────────────
    'my_activity_title': {
      'ko': '나의 활동', 'en': 'My Activity', 'ja': '活動履歴', 'zh': '我的活动', 'es': 'Mi Actividad',
    },
    'tab_recent': {
      'ko': '최근 본 강의', 'en': 'Recent', 'ja': '最近', 'zh': '最近', 'es': 'Reciente',
    },
    'tab_notes': {
      'ko': '내 노트', 'en': 'Notes', 'ja': 'ノート', 'zh': '笔记', 'es': 'Notas',
    },
    'tab_my_qa': {
      'ko': '강의 Q&A', 'en': 'Q&A', 'ja': 'Q&A', 'zh': 'Q&A', 'es': 'Q&A',
    },
    'tab_expert': {
      'ko': '내 상담', 'en': 'My Q&A', 'ja': '相談履歴', 'zh': '我的咨询', 'es': 'Mi Consulta',
    },
    'tab_favorites': {
      'ko': '즐겨찾기', 'en': 'Favorites', 'ja': 'お気に入り', 'zh': '收藏', 'es': 'Favoritos',
    },
    'total_count': {
      'ko': '총 {n}개', 'en': 'Total {n}', 'ja': '合計{n}件', 'zh': '共{n}个', 'es': 'Total {n}',
    },
    'delete_all': {
      'ko': '전체 삭제', 'en': 'Delete All', 'ja': '全削除', 'zh': '全部删除', 'es': 'Borrar Todo',
    },
    'delete_recent_title': {
      'ko': '최근 본 강의 삭제', 'en': 'Delete History', 'ja': '履歴削除', 'zh': '删除历史', 'es': 'Borrar Historial',
    },
    'delete_recent_content': {
      'ko': '시청 기록을 모두 삭제하시겠습니까?', 'en': 'Delete all watch history?', 'ja': '視聴履歴をすべて削除しますか？', 'zh': '确认删除所有观看记录？', 'es': '¿Borrar todo el historial?',
    },
    'delete_btn': {
      'ko': '삭제', 'en': 'Delete', 'ja': '削除', 'zh': '删除', 'es': 'Borrar',
    },
    'empty_recent': {
      'ko': '최근 본 영상이 없어요', 'en': 'No recent videos', 'ja': '最近見た動画なし', 'zh': '暂无最近观看', 'es': 'Sin videos recientes',
    },
    'empty_recent_sub': {
      'ko': '강의를 시청하면 여기에 기록됩니다', 'en': 'Watch lectures to see them here', 'ja': '授業を見ると記録されます', 'zh': '观看课程后将显示在这里', 'es': 'Ver clases para mostrarlas aquí',
    },
    'empty_notes': {
      'ko': '저장된 노트가 없어요', 'en': 'No saved notes', 'ja': '保存したノートなし', 'zh': '暂无笔记', 'es': 'Sin notas guardadas',
    },
    'empty_notes_sub': {
      'ko': '강의 재생 중 노트를 작성해보세요', 'en': 'Take notes while watching', 'ja': '授業中にノートを書いてみましょう', 'zh': '观看时记录笔记', 'es': 'Toma notas mientras ves',
    },
    'empty_qa': {
      'ko': '작성한 Q&A가 없어요', 'en': 'No Q&A written', 'ja': 'Q&Aがありません', 'zh': '暂无Q&A', 'es': 'Sin Q&A',
    },
    'empty_qa_sub': {
      'ko': '강의 재생 중 궁금한 점을 질문해보세요', 'en': 'Ask questions while watching', 'ja': '授業中に質問してみましょう', 'zh': '观看时提问', 'es': 'Haz preguntas mientras ves',
    },
    'empty_consult': {
      'ko': '작성한 상담이 없어요', 'en': 'No consultations', 'ja': '相談がありません', 'zh': '暂无咨询', 'es': 'Sin consultas',
    },
    'empty_consult_sub': {
      'ko': '내 상담 탭에서 질문을 등록해보세요', 'en': 'Go to My Q&A to ask', 'ja': '相談タブで質問してみましょう', 'zh': '在我的咨询标签提问', 'es': 'Ve a Mi Consulta para preguntar',
    },
    'empty_favorites': {
      'ko': '즐겨찾기한 강의가 없어요', 'en': 'No favorites', 'ja': 'お気に入りがありません', 'zh': '暂无收藏', 'es': 'Sin favoritos',
    },
    'empty_favorites_sub': {
      'ko': '강의 카드의 북마크 아이콘을 눌러 저장해보세요', 'en': 'Tap bookmark icon to save', 'ja': 'ブックマークアイコンをタップして保存', 'zh': '点击收藏图标保存', 'es': 'Toca el ícono de marcador',
    },
    'fav_count': {
      'ko': '즐겨찾기 {n}개', 'en': '{n} Favorites', 'ja': 'お気に入り{n}件', 'zh': '收藏{n}个', 'es': '{n} Favoritos',
    },
    'note_open': {
      'ko': '노트 열기', 'en': 'Open Note', 'ja': 'ノートを開く', 'zh': '打开笔记', 'es': 'Abrir Nota',
    },
    'stroke_count': {
      'ko': '필기 {n}획', 'en': '{n} strokes', 'ja': '{n}ストローク', 'zh': '{n}笔', 'es': '{n} trazos',
    },

    // ────────────────────────────────────────────
    // 스토어 화면
    // ────────────────────────────────────────────
    'store_title': {
      'ko': '스토어', 'en': 'Store', 'ja': 'ストア', 'zh': '商店', 'es': 'Tienda',
    },
    'premium_benefits': {
      'ko': '프리미엄 혜택', 'en': 'Premium Benefits', 'ja': 'プレミアム特典', 'zh': '高级权益', 'es': 'Beneficios Premium',
    },
    'unlimited_lectures': {
      'ko': '모든 강의 무제한 수강', 'en': 'Unlimited Access to All Lectures', 'ja': 'すべての授業を無制限受講', 'zh': '无限制学习所有课程', 'es': 'Acceso Ilimitado a Clases',
    },
    'store_subtitle': {
      'ko': '10,000개 이상의 2분 강의를 마음껏 보세요', 'en': 'Watch 10,000+ 2-min lectures freely', 'ja': '10,000以上の2分授業を自由に見ましょう', 'zh': '自由观看10,000+个2分钟课程', 'es': 'Ve +10,000 clases de 2 min libremente',
    },
    'select_plan': {
      'ko': '이용권 선택', 'en': 'Select Plan', 'ja': 'プラン選択', 'zh': '选择套餐', 'es': 'Seleccionar Plan',
    },
    'buy_plan': {
      'ko': '구매하기', 'en': 'Buy Now', 'ja': '購入する', 'zh': '立即购买', 'es': 'Comprar Ahora',
    },
    'payment_notice': {
      'ko': '결제는 앱 출시 후 실제 결제 시스템과 연동됩니다', 'en': 'Payment system will be connected after launch', 'ja': 'アプリリリース後に実際の決済システムと連動します', 'zh': '应用发布后与实际支付系统连接', 'es': 'El pago se conectará al sistema real al lanzar',
    },
    'no_payment_history': {
      'ko': '결제 내역이 없습니다', 'en': 'No payment history', 'ja': '決済履歴がありません', 'zh': '暂无付款记录', 'es': 'Sin historial de pagos',
    },
    'payment_history_tab': {
      'ko': '결제 내역', 'en': 'Payment History', 'ja': '決済履歴', 'zh': '付款记录', 'es': 'Historial',
    },
    'buy_confirm_title': {
      'ko': '구매 확인', 'en': 'Confirm Purchase', 'ja': '購入確認', 'zh': '确认购买', 'es': 'Confirmar Compra',
    },

    // ────────────────────────────────────────────
    // 교과서 진도 화면
    // ────────────────────────────────────────────
    'curriculum_title': {
      'ko': '진도학습', 'en': 'Progress', 'ja': '進度学習', 'zh': '进度学习', 'es': 'Progreso',
    },
    'select_grade': {
      'ko': '학년 선택', 'en': 'Select Grade', 'ja': '学年選択', 'zh': '选择年级', 'es': 'Seleccionar Grado',
    },
    'select_unit': {
      'ko': '단원 선택', 'en': 'Select Unit', 'ja': 'ユニット選択', 'zh': '选择单元', 'es': 'Seleccionar Unidad',
    },
    'select_grade_first': {
      'ko': '먼저 학년을 선택해 주세요', 'en': 'Please select a grade first', 'ja': '先に学年を選択してください', 'zh': '请先选择年级', 'es': 'Selecciona un grado primero',
    },
    'no_unit_for_filter': {
      'ko': '선택한 조건에 해당하는 단원이 없습니다', 'en': 'No units for selected filter', 'ja': '選択条件に合うユニットがありません', 'zh': '没有符合条件的单元', 'es': 'Sin unidades para el filtro',
    },
    'reset_filter': {
      'ko': '필터 초기화', 'en': 'Reset Filter', 'ja': 'フィルターリセット', 'zh': '重置筛选', 'es': 'Restablecer Filtro',
    },
    'lecture_count_unit': {
      'ko': '강의 {n}개', 'en': '{n} lectures', 'ja': '授業{n}本', 'zh': '{n}节课', 'es': '{n} clases',
    },
    'no_unit_for_grade': {
      'ko': '선택한 학년에 해당하는 단원이 없습니다', 'en': 'No units for selected grade', 'ja': '選択した学年のユニットがありません', 'zh': '该年级没有单元', 'es': 'Sin unidades para este grado',
    },

    // ────────────────────────────────────────────
    // 일정 화면
    // ────────────────────────────────────────────
    'schedule_title': {
      'ko': '학습 일정', 'en': 'Study Schedule', 'ja': '学習スケジュール', 'zh': '学习日程', 'es': 'Horario de Estudio',
    },
    'add_schedule': {
      'ko': '일정 추가', 'en': 'Add Schedule', 'ja': '日程追加', 'zh': '添加日程', 'es': 'Agregar Horario',
    },
    'no_schedule': {
      'ko': '일정이 없습니다', 'en': 'No schedule', 'ja': '日程がありません', 'zh': '暂无日程', 'es': 'Sin horario',
    },
  };

  /// 특정 언어 코드로 번역 반환
  static String tLang(String langCode, String key) {
    final langMap = _translations[key];
    if (langMap == null) return key;
    return langMap[langCode] ?? langMap['ko'] ?? key;
  }

  /// fallback 언어 코드 포함 번역
  static String t(String langCode, String key, {String fallback = ''}) {
    final result = tLang(langCode, key);
    if (result == key && fallback.isNotEmpty) return fallback;
    return result;
  }
}
