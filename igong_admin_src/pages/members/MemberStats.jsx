import { useState } from 'react'
import { mockStats } from '../../utils/mockData'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line } from 'recharts'

export default function MemberStats() {
  const [dateFrom, setDateFrom] = useState('2025-03-01')
  const [dateTo, setDateTo] = useState('2025-03-31')

  const stats = [
    { label: '기간 방문자', value: mockStats.todayVisitors * 31, icon: '👀', color: '#4f46e5', bg: '#ede9fe' },
    { label: '신규 가입', value: mockStats.newMembersThisMonth, icon: '🆕', color: '#059669', bg: '#d1fae5' },
    { label: '탈퇴 회원', value: 12, icon: '👋', color: '#dc2626', bg: '#fee2e2' },
    { label: '전체 회원', value: mockStats.totalMembers, icon: '👥', color: '#0891b2', bg: '#e0f2fe' },
  ]

  return (
    <div style={s.root}>
      {/* 날짜 필터 */}
      <div style={s.filterBox}>
        <div style={s.filterInner}>
          <span style={s.filterLabel}>조회 기간</span>
          <input type="date" style={s.dateInput} value={dateFrom} onChange={e => setDateFrom(e.target.value)} />
          <span style={{ fontSize: 13, color: '#888' }}>~</span>
          <input type="date" style={s.dateInput} value={dateTo} onChange={e => setDateTo(e.target.value)} />
          <button style={s.btnOutline} onClick={() => { setDateFrom('2025-03-01'); setDateTo('2025-03-31') }}>이번달</button>
          <button style={s.btnOutline} onClick={() => { setDateFrom('2025-02-01'); setDateTo('2025-02-28') }}>지난달</button>
          <button style={s.btnPrimary}>조회</button>
        </div>
        <button style={s.btnOutline} onClick={() => alert('엑셀 다운로드')}>📥 엑셀 다운로드</button>
      </div>

      {/* 통계 카드 */}
      <div style={s.cards}>
        {stats.map((c, i) => (
          <div key={i} style={s.card}>
            <div style={{ ...s.cardIcon, background: c.bg, color: c.color }}>{c.icon}</div>
            <div>
              <div style={s.cardLabel}>{c.label}</div>
              <div style={{ ...s.cardValue, color: c.color }}>{c.value.toLocaleString()}</div>
            </div>
          </div>
        ))}
      </div>

      {/* 차트 */}
      <div style={s.charts}>
        <div style={s.chartBox}>
          <div style={s.chartTitle}>📈 일별 방문자 현황</div>
          <ResponsiveContainer width="100%" height={260}>
            <LineChart data={mockStats.visitData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} interval={4} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Line type="monotone" dataKey="visitors" stroke="#4f46e5" strokeWidth={2} dot={false} name="방문자" />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <div style={s.chartBox}>
          <div style={s.chartTitle}>👥 일별 신규 가입</div>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={mockStats.visitData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 11 }} interval={4} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="members" fill="#059669" radius={[4, 4, 0, 0]} name="신규가입" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}

const s = {
  root: { display: 'flex', flexDirection: 'column', gap: 16 },
  filterBox: { background: '#fff', borderRadius: 12, padding: '16px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  filterInner: { display: 'flex', gap: 12, alignItems: 'center' },
  filterLabel: { fontSize: 13, fontWeight: 600, color: '#555' },
  dateInput: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
  cards: { display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 },
  card: { background: '#fff', borderRadius: 14, padding: '20px', display: 'flex', alignItems: 'center', gap: 16, boxShadow: '0 1px 4px rgba(0,0,0,0.06)' },
  cardIcon: { width: 48, height: 48, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20, flexShrink: 0 },
  cardLabel: { fontSize: 12, color: '#888', marginBottom: 4 },
  cardValue: { fontSize: 24, fontWeight: 800 },
  charts: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 },
  chartBox: { background: '#fff', borderRadius: 14, padding: '20px', boxShadow: '0 1px 4px rgba(0,0,0,0.06)' },
  chartTitle: { fontSize: 14, fontWeight: 700, color: '#1a1a2e', marginBottom: 16 },
}
