import { useState } from 'react'
import { mockPayments } from '../../utils/mockData'

export default function MemberPayments() {
  const [search, setSearch] = useState({ name: '', userId: '', nickname: '' })
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [payments] = useState(mockPayments)

  const filtered = payments.filter(p =>
    (!search.name || p.name.includes(search.name)) &&
    (!search.userId || p.userId.includes(search.userId)) &&
    (!search.nickname || p.nickname.includes(search.nickname))
  )
  const total = filtered.length
  const paged = filtered.slice((page - 1) * pageSize, page * pageSize)
  const totalPages = Math.ceil(total / pageSize)

  const exportCsv = () => {
    const rows = [['번호', '이름', '아이디', '닉네임', '상품', '결제수단', '금액', '결제일']]
    filtered.forEach(p => rows.push([p.id, p.name, p.userId, p.nickname, p.product, p.method, p.amount, p.payDate]))
    const csv = rows.map(r => r.join(',')).join('\n')
    const a = document.createElement('a'); a.href = 'data:text/csv;charset=utf-8,\uFEFF' + csv
    a.download = '결제회원.csv'; a.click()
  }

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        {[['이름', 'name'], ['아이디', 'userId'], ['닉네임', 'nickname']].map(([label, key]) => (
          <div key={key} style={s.searchField}>
            <span style={s.searchLabel}>{label}</span>
            <input style={s.searchInput} value={search[key]}
              onChange={e => { setSearch(p => ({ ...p, [key]: e.target.value })); setPage(1) }}
              placeholder={`${label} 검색`} />
          </div>
        ))}
        <button style={s.btnOutline} onClick={() => setSearch({ name: '', userId: '', nickname: '' })}>초기화</button>
      </div>

      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{total}</b>건</span>
        <div style={s.headerBtns}>
          <select style={s.select} value={pageSize} onChange={e => { setPageSize(+e.target.value); setPage(1) }}>
            {[10, 20, 30, 50].map(n => <option key={n} value={n}>{n}개씩</option>)}
          </select>
          <button style={s.btnPrimary} onClick={exportCsv}>📥 엑셀 다운로드</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>{['번호', '이름', '아이디', '닉네임', '상품', '결제수단', '금액', '결제일'].map(h => (
              <th key={h} style={s.th}>{h}</th>
            ))}</tr>
          </thead>
          <tbody>
            {paged.map(p => (
              <tr key={p.id} style={s.tr}>
                <td style={s.td}>{p.id}</td>
                <td style={s.td}><b>{p.name}</b></td>
                <td style={s.td}>{p.userId}</td>
                <td style={s.td}>{p.nickname}</td>
                <td style={s.td}>
                  <span style={{ ...s.badge, background: '#dbeafe', color: '#1d4ed8' }}>{p.product}</span>
                </td>
                <td style={s.td}>{p.method}</td>
                <td style={s.td}><b style={{ color: '#059669' }}>{p.amount.toLocaleString()}원</b></td>
                <td style={s.td}>{p.payDate}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={s.pagination}>
        {[['<<', 1], ['<', Math.max(1, page - 1)]].map(([label, to]) => (
          <button key={label} style={s.pageBtn} onClick={() => setPage(to)} disabled={page === 1}>{label}</button>
        ))}
        {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
          const p = Math.max(1, page - 2) + i
          return p <= totalPages ? (
            <button key={p} style={{ ...s.pageBtn, ...(p === page ? s.pageBtnActive : {}) }} onClick={() => setPage(p)}>{p}</button>
          ) : null
        })}
        {['>', '>>'].map((label, i) => (
          <button key={label} style={s.pageBtn} onClick={() => setPage(i === 0 ? Math.min(totalPages, page + 1) : totalPages)} disabled={page === totalPages}>{label}</button>
        ))}
        <span style={s.pageInfo}>{page} / {totalPages}</span>
      </div>
    </div>
  )
}

const s = {
  root: { display: 'flex', flexDirection: 'column', gap: 16 },
  searchBox: { background: '#fff', borderRadius: 12, padding: '16px 20px', display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  searchField: { display: 'flex', alignItems: 'center', gap: 8 },
  searchLabel: { fontSize: 13, color: '#555', whiteSpace: 'nowrap', fontWeight: 600 },
  searchInput: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, width: 140 },
  tableHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  total: { fontSize: 13, color: '#555' },
  headerBtns: { display: 'flex', gap: 10, alignItems: 'center' },
  select: { padding: '7px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse', minWidth: 800 },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  tr: { borderBottom: '1px solid #fafafa' },
  td: { padding: '10px 12px', fontSize: 13, color: '#333' },
  badge: { padding: '3px 10px', borderRadius: 20, fontSize: 11, fontWeight: 600 },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
  pagination: { display: 'flex', gap: 6, alignItems: 'center', justifyContent: 'center' },
  pageBtn: { padding: '6px 12px', border: '1.5px solid #e5e7eb', borderRadius: 7, fontSize: 13, cursor: 'pointer', background: '#fff' },
  pageBtnActive: { background: '#4f46e5', color: '#fff', borderColor: '#4f46e5' },
  pageInfo: { fontSize: 13, color: '#888', marginLeft: 8 },
}
