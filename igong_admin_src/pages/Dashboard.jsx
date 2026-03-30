import { mockStats, mockVideos } from '../utils/mockData'
import { AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

const statCards = [
  { label: '전체 회원', value: mockStats.totalMembers.toLocaleString(), sub: '명', icon: '👥', color: '#4f46e5', bg: '#ede9fe' },
  { label: '유료 회원', value: mockStats.paidMembers.toLocaleString(), sub: '명', icon: '💎', color: '#0891b2', bg: '#e0f2fe' },
  { label: '오늘 방문자', value: mockStats.todayVisitors.toLocaleString(), sub: '명', icon: '📈', color: '#059669', bg: '#d1fae5' },
  { label: '총 동영상', value: mockStats.totalVideos.toLocaleString(), sub: '개', icon: '🎬', color: '#d97706', bg: '#fef3c7' },
  { label: '이번달 신규', value: mockStats.newMembersThisMonth.toLocaleString(), sub: '명', icon: '🆕', color: '#dc2626', bg: '#fee2e2' },
  { label: '이번달 매출', value: (mockStats.revenueThisMonth / 10000).toLocaleString(), sub: '만원', icon: '💰', color: '#7c3aed', bg: '#f3e8ff' },
]

export default function Dashboard() {
  return (
    <div style={styles.root}>
      {/* 상단 통계 카드 */}
      <div style={styles.cards}>
        {statCards.map((c, i) => (
          <div key={i} style={styles.card}>
            <div style={{ ...styles.cardIcon, background: c.bg, color: c.color }}>{c.icon}</div>
            <div style={styles.cardBody}>
              <div style={styles.cardLabel}>{c.label}</div>
              <div style={styles.cardValue}>
                <span style={{ ...styles.cardNum, color: c.color }}>{c.value}</span>
                <span style={styles.cardSub}>{c.sub}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* 차트 영역 */}
      <div style={styles.charts}>
        {/* 방문자 추이 */}
        <div style={styles.chartBox}>
          <div style={styles.chartTitle}>📊 최근 30일 방문자 추이</div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={mockStats.visitData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="colorVisitors" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#4f46e5" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#4f46e5" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} interval={4} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Area type="monotone" dataKey="visitors" stroke="#4f46e5" fill="url(#colorVisitors)" name="방문자" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* 신규 회원 */}
        <div style={styles.chartBox}>
          <div style={styles.chartTitle}>👥 최근 30일 신규 회원</div>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={mockStats.visitData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} interval={4} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="members" fill="#7c3aed" radius={[4, 4, 0, 0]} name="신규 회원" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* 하단 테이블 */}
      <div style={styles.bottom}>
        {/* 인기 동영상 */}
        <div style={styles.tableBox}>
          <div style={styles.tableTitle}>🔥 인기 동영상 TOP 5</div>
          <table style={styles.table}>
            <thead>
              <tr>
                {['순위', '제목', '강사', '조회수', '평점'].map(h => (
                  <th key={h} style={styles.th}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {mockStats.topVideos.map((v, i) => (
                <tr key={v.id} style={styles.tr}>
                  <td style={styles.td}>
                    <span style={{ ...styles.rank, background: i < 3 ? ['#f59e0b', '#9ca3af', '#cd7c2a'][i] : '#e5e7eb', color: i < 3 ? '#fff' : '#888' }}>
                      {i + 1}
                    </span>
                  </td>
                  <td style={{ ...styles.td, maxWidth: 200 }}>
                    <div style={styles.truncate}>{v.title}</div>
                  </td>
                  <td style={styles.td}>{v.instructor}</td>
                  <td style={styles.td}>{v.views.toLocaleString()}</td>
                  <td style={styles.td}>
                    <span style={styles.rating}>⭐ {v.rating}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* 최근 활동 요약 */}
        <div style={styles.activityBox}>
          <div style={styles.tableTitle}>🔔 최근 활동</div>
          <div style={styles.activityList}>
            {[
              { icon: '👤', text: '신규 회원 가입', detail: 'user050 (김민준)', time: '방금 전', color: '#4f46e5' },
              { icon: '💬', text: '새 Q&A 등록', detail: '삼각함수 질문', time: '5분 전', color: '#0891b2' },
              { icon: '💳', text: '결제 완료', detail: '90일 이용권', time: '12분 전', color: '#059669' },
              { icon: '📢', text: '공지사항 등록', detail: '앱 업데이트 안내', time: '1시간 전', color: '#d97706' },
              { icon: '🎬', text: '동영상 업로드', detail: '수학 이차방정식 31강', time: '2시간 전', color: '#7c3aed' },
              { icon: '🎧', text: '1:1 문의 접수', detail: '결제 관련 문의', time: '3시간 전', color: '#dc2626' },
            ].map((a, i) => (
              <div key={i} style={styles.activityItem}>
                <div style={{ ...styles.activityIcon, background: a.color + '18', color: a.color }}>{a.icon}</div>
                <div style={styles.activityContent}>
                  <div style={styles.activityText}>{a.text}</div>
                  <div style={styles.activityDetail}>{a.detail}</div>
                </div>
                <div style={styles.activityTime}>{a.time}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

const styles = {
  root: { display: 'flex', flexDirection: 'column', gap: 24 },
  cards: { display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 },
  card: {
    background: '#fff', borderRadius: 14, padding: '20px 20px',
    display: 'flex', alignItems: 'center', gap: 16,
    boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
  },
  cardIcon: {
    width: 52, height: 52, borderRadius: 14,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 22, flexShrink: 0,
  },
  cardBody: { flex: 1 },
  cardLabel: { fontSize: 12, color: '#888', marginBottom: 4 },
  cardValue: { display: 'flex', alignItems: 'baseline', gap: 4 },
  cardNum: { fontSize: 26, fontWeight: 800 },
  cardSub: { fontSize: 13, color: '#888' },
  charts: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 },
  chartBox: {
    background: '#fff', borderRadius: 14, padding: '20px',
    boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
  },
  chartTitle: { fontSize: 14, fontWeight: 700, color: '#1a1a2e', marginBottom: 16 },
  bottom: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 },
  tableBox: {
    background: '#fff', borderRadius: 14, padding: '20px',
    boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
  },
  tableTitle: { fontSize: 14, fontWeight: 700, color: '#1a1a2e', marginBottom: 14 },
  table: { width: '100%', borderCollapse: 'collapse' },
  th: {
    padding: '8px 10px', textAlign: 'left',
    fontSize: 11, color: '#888', fontWeight: 600,
    borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap',
  },
  tr: { borderBottom: '1px solid #fafafa' },
  td: { padding: '10px 10px', fontSize: 13, color: '#333', verticalAlign: 'middle' },
  rank: {
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    width: 22, height: 22, borderRadius: '50%', fontSize: 11, fontWeight: 700,
  },
  truncate: {
    maxWidth: 180, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
  },
  rating: { fontSize: 12, color: '#f59e0b', fontWeight: 600 },
  activityBox: {
    background: '#fff', borderRadius: 14, padding: '20px',
    boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
  },
  activityList: { display: 'flex', flexDirection: 'column', gap: 12 },
  activityItem: { display: 'flex', alignItems: 'center', gap: 12 },
  activityIcon: {
    width: 36, height: 36, borderRadius: 10,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 16, flexShrink: 0,
  },
  activityContent: { flex: 1, minWidth: 0 },
  activityText: { fontSize: 13, fontWeight: 600, color: '#1a1a2e' },
  activityDetail: { fontSize: 11, color: '#888', marginTop: 1 },
  activityTime: { fontSize: 11, color: '#bbb', flexShrink: 0 },
}
