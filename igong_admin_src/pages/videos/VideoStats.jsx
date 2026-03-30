import { mockVideos, mockStats } from '../../utils/mockData'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

export default function VideoStats() {
  const topByViews = [...mockVideos].sort((a, b) => b.views - a.views).slice(0, 10)
  const topByRating = [...mockVideos].sort((a, b) => b.rating - a.rating).slice(0, 10)

  return (
    <div style={s.root}>
      <div style={s.cards}>
        {[
          { label: '총 동영상', value: mockStats.totalVideos.toLocaleString(), icon: '🎬', color: '#4f46e5', bg: '#ede9fe' },
          { label: '이번달 업로드', value: '124', icon: '📤', color: '#059669', bg: '#d1fae5' },
          { label: '총 조회수', value: '2,341,456', icon: '👀', color: '#0891b2', bg: '#e0f2fe' },
          { label: '평균 평점', value: '4.3', icon: '⭐', color: '#d97706', bg: '#fef3c7' },
        ].map((c, i) => (
          <div key={i} style={s.card}>
            <div style={{ ...s.cardIcon, background: c.bg, color: c.color }}>{c.icon}</div>
            <div><div style={s.cl}>{c.label}</div><div style={{ ...s.cv, color: c.color }}>{c.value}</div></div>
          </div>
        ))}
      </div>

      <div style={s.charts}>
        <div style={s.chartBox}>
          <div style={s.chartTitle}>🔥 인기 동영상 TOP 10 (조회수)</div>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={topByViews} margin={{ top: 5, right: 10, left: -10, bottom: 60 }} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis type="number" tick={{ fontSize: 11 }} />
              <YAxis type="category" dataKey="title" tick={{ fontSize: 10 }} width={120} />
              <Tooltip formatter={v => v.toLocaleString()} />
              <Bar dataKey="views" fill="#4f46e5" radius={[0, 4, 4, 0]} name="조회수" />
            </BarChart>
          </ResponsiveContainer>
        </div>
        <div style={s.chartBox}>
          <div style={s.chartTitle}>⭐ 평점 높은 동영상 TOP 10</div>
          <div style={s.ratingList}>
            {topByRating.map((v, i) => (
              <div key={v.id} style={s.ratingItem}>
                <span style={{ ...s.rank, background: i < 3 ? ['#f59e0b', '#9ca3af', '#cd7c2a'][i] : '#e5e7eb', color: i < 3 ? '#fff' : '#888' }}>{i + 1}</span>
                <div style={s.ratingInfo}>
                  <div style={s.ratingTitle}>{v.title}</div>
                  <div style={s.ratingSub}>{v.instructor} · {v.category}</div>
                </div>
                <div style={s.ratingScore}>⭐ {v.rating}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

const s = {
  root: { display: 'flex', flexDirection: 'column', gap: 16 },
  cards: { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 },
  card: { background: '#fff', borderRadius: 14, padding: '20px', display: 'flex', alignItems: 'center', gap: 16, boxShadow: '0 1px 4px rgba(0,0,0,0.06)' },
  cardIcon: { width: 48, height: 48, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0 },
  cl: { fontSize: 12, color: '#888', marginBottom: 4 }, cv: { fontSize: 22, fontWeight: 800 },
  charts: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 },
  chartBox: { background: '#fff', borderRadius: 14, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.06)' },
  chartTitle: { fontSize: 14, fontWeight: 700, color: '#1a1a2e', marginBottom: 16 },
  ratingList: { display: 'flex', flexDirection: 'column', gap: 10 },
  ratingItem: { display: 'flex', alignItems: 'center', gap: 12 },
  rank: { width: 22, height: 22, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 11, fontWeight: 700, flexShrink: 0 },
  ratingInfo: { flex: 1, minWidth: 0 },
  ratingTitle: { fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' },
  ratingSub: { fontSize: 11, color: '#888', marginTop: 1 },
  ratingScore: { fontSize: 13, color: '#f59e0b', fontWeight: 700, flexShrink: 0 },
}
