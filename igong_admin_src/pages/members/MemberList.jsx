import { useState } from 'react'
import { mockMembers } from '../../utils/mockData'

export default function MemberList() {
  const [search, setSearch] = useState({ name: '', userId: '', nickname: '' })
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [selected, setSelected] = useState(null)
  const [editModal, setEditModal] = useState(false)
  const [editData, setEditData] = useState(null)
  const [members, setMembers] = useState(mockMembers)

  const filtered = members.filter(m =>
    (!search.name || m.name.includes(search.name)) &&
    (!search.userId || m.userId.includes(search.userId)) &&
    (!search.nickname || m.nickname.includes(search.nickname))
  )
  const total = filtered.length
  const paged = filtered.slice((page - 1) * pageSize, page * pageSize)
  const totalPages = Math.ceil(total / pageSize)

  const openEdit = (m) => { setEditData({ ...m }); setEditModal(true) }
  const saveEdit = () => {
    setMembers(prev => prev.map(m => m.id === editData.id ? editData : m))
    setEditModal(false)
  }

  const exportCsv = () => {
    const rows = [['번호', '이름', '아이디', '닉네임', '휴대폰', '가입일', '권한', '만료일']]
    filtered.forEach(m => rows.push([m.id, m.name, m.userId, m.nickname, m.phone, m.joinDate, m.permission, m.expireDate]))
    const csv = rows.map(r => r.join(',')).join('\n')
    const a = document.createElement('a'); a.href = 'data:text/csv;charset=utf-8,\uFEFF' + csv
    a.download = '회원목록.csv'; a.click()
  }

  return (
    <div style={s.root}>
      {/* 검색 */}
      <div style={s.searchBox}>
        {[['이름', 'name'], ['아이디', 'userId'], ['닉네임', 'nickname']].map(([label, key]) => (
          <div key={key} style={s.searchField}>
            <span style={s.searchLabel}>{label}</span>
            <input style={s.searchInput} value={search[key]}
              onChange={e => { setSearch(p => ({ ...p, [key]: e.target.value })); setPage(1) }}
              placeholder={`${label} 검색`} />
          </div>
        ))}
        <button style={s.btnOutline} onClick={() => { setSearch({ name: '', userId: '', nickname: '' }); setPage(1) }}>초기화</button>
      </div>

      {/* 헤더 */}
      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{total}</b>명</span>
        <div style={s.headerBtns}>
          <select style={s.select} value={pageSize} onChange={e => { setPageSize(+e.target.value); setPage(1) }}>
            {[10, 20, 30, 50].map(n => <option key={n} value={n}>{n}개씩</option>)}
          </select>
          <button style={s.btnPrimary} onClick={exportCsv}>📥 엑셀 다운로드</button>
        </div>
      </div>

      {/* 테이블 */}
      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>{['번호', '이름', '아이디', '닉네임', '휴대폰', '가입일', '권한', '만료일', '관리'].map(h => (
              <th key={h} style={s.th}>{h}</th>
            ))}</tr>
          </thead>
          <tbody>
            {paged.map(m => (
              <tr key={m.id} style={s.tr} onClick={() => setSelected(m.id === selected ? null : m.id)}>
                <td style={s.td}>{m.id}</td>
                <td style={s.td}><b>{m.name}</b></td>
                <td style={s.td}>{m.userId}</td>
                <td style={s.td}>{m.nickname}</td>
                <td style={s.td}>{m.phone}</td>
                <td style={s.td}>{m.joinDate}</td>
                <td style={s.td}>
                  <span style={{ ...s.badge, background: m.permission === 'Y' ? '#d1fae5' : '#f3f4f6', color: m.permission === 'Y' ? '#059669' : '#888' }}>
                    {m.permission === 'Y' ? '유료' : '무료'}
                  </span>
                </td>
                <td style={s.td}>{m.expireDate}</td>
                <td style={s.td} onClick={e => e.stopPropagation()}>
                  <button style={s.btnSm} onClick={() => openEdit(m)}>수정</button>
                  <button style={{ ...s.btnSm, ...s.btnDanger }} onClick={() => alert('대리 로그인: ' + m.userId)}>대리로그인</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* 페이지네이션 */}
      <div style={s.pagination}>
        <button style={s.pageBtn} onClick={() => setPage(1)} disabled={page === 1}>{'<<'}</button>
        <button style={s.pageBtn} onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>{'<'}</button>
        {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
          const p = Math.max(1, page - 2) + i
          if (p > totalPages) return null
          return <button key={p} style={{ ...s.pageBtn, ...(p === page ? s.pageBtnActive : {}) }} onClick={() => setPage(p)}>{p}</button>
        })}
        <button style={s.pageBtn} onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>{'>'}</button>
        <button style={s.pageBtn} onClick={() => setPage(totalPages)} disabled={page === totalPages}>{'>>'}</button>
        <span style={s.pageInfo}>{page} / {totalPages} 페이지</span>
      </div>

      {/* 수정 모달 */}
      {editModal && editData && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>회원 정보 수정</div>
            <div style={s.modalFields}>
              {[
                ['아이디 (변경불가)', 'userId', true],
                ['이름', 'name', false],
                ['닉네임', 'nickname', false],
                ['휴대폰', 'phone', false],
                ['비밀번호 (새로설정)', 'pw', false],
              ].map(([label, key, disabled]) => (
                <div key={key} style={s.mField}>
                  <label style={s.mLabel}>{label}</label>
                  <input style={{ ...s.mInput, background: disabled ? '#f8f8f8' : '#fff' }}
                    value={editData[key] || ''} disabled={disabled}
                    onChange={e => setEditData(p => ({ ...p, [key]: e.target.value }))} />
                </div>
              ))}
              <div style={s.mField}>
                <label style={s.mLabel}>권한</label>
                <select style={s.mInput} value={editData.permission}
                  onChange={e => setEditData(p => ({ ...p, permission: e.target.value }))}>
                  <option value="Y">유료</option>
                  <option value="N">무료</option>
                </select>
              </div>
            </div>
            <div style={s.modalBtns}>
              <button style={s.btnPrimary} onClick={saveEdit}>저장</button>
              <button style={s.btnOutline} onClick={() => setEditModal(false)}>취소</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const s = {
  root: { display: 'flex', flexDirection: 'column', gap: 16 },
  searchBox: {
    background: '#fff', borderRadius: 12, padding: '16px 20px',
    display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center',
    boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
  },
  searchField: { display: 'flex', alignItems: 'center', gap: 8 },
  searchLabel: { fontSize: 13, color: '#555', whiteSpace: 'nowrap', fontWeight: 600 },
  searchInput: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, width: 140 },
  tableHeader: {
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
  },
  total: { fontSize: 13, color: '#555' },
  headerBtns: { display: 'flex', gap: 10, alignItems: 'center' },
  select: { padding: '7px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse', minWidth: 900 },
  th: {
    padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600,
    background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap',
  },
  tr: { borderBottom: '1px solid #fafafa', cursor: 'pointer', transition: 'background 0.15s' },
  td: { padding: '10px 12px', fontSize: 13, color: '#333' },
  badge: { padding: '3px 10px', borderRadius: 20, fontSize: 11, fontWeight: 600 },
  btnSm: {
    padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6,
    fontSize: 12, cursor: 'pointer', marginRight: 4,
  },
  btnDanger: { background: '#fff0f0', color: '#e53e3e' },
  btnPrimary: {
    padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)',
    color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer',
  },
  btnOutline: {
    padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb',
    borderRadius: 8, fontSize: 13, cursor: 'pointer',
  },
  pagination: { display: 'flex', gap: 6, alignItems: 'center', justifyContent: 'center' },
  pageBtn: { padding: '6px 12px', border: '1.5px solid #e5e7eb', borderRadius: 7, fontSize: 13, cursor: 'pointer', background: '#fff' },
  pageBtnActive: { background: '#4f46e5', color: '#fff', borderColor: '#4f46e5' },
  pageInfo: { fontSize: 13, color: '#888', marginLeft: 8 },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 480, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 24, color: '#1a1a2e' },
  modalFields: { display: 'flex', flexDirection: 'column', gap: 14 },
  mField: { display: 'flex', flexDirection: 'column', gap: 4 },
  mLabel: { fontSize: 12, color: '#666', fontWeight: 600 },
  mInput: { padding: '10px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  modalBtns: { display: 'flex', gap: 10, marginTop: 24, justifyContent: 'flex-end' },
}
