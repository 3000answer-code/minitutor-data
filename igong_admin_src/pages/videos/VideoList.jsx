import { useState } from 'react'
import { mockVideos, mockInstructors, mockSeries } from '../../utils/mockData'

const CATEGORIES = ['전체', '수학/중등', '수학/고등', '영어/중등', '영어/고등', '과학/중등', '과학/고등', '국어/중등', '국어/고등', '사회/중등', '사회/고등', '기타']

export default function VideoList() {
  const [search, setSearch] = useState({ category: '전체', title: '', visible: '' })
  const [videos, setVideos] = useState(mockVideos)
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [modal, setModal] = useState(false)
  const [editData, setEditData] = useState(null)
  const [selected, setSelected] = useState([])

  const filtered = videos.filter(v =>
    (search.category === '전체' || v.category === search.category) &&
    (!search.title || v.title.includes(search.title)) &&
    (!search.visible || v.visible === search.visible)
  )
  const total = filtered.length
  const paged = filtered.slice((page - 1) * pageSize, page * pageSize)
  const totalPages = Math.ceil(total / pageSize)

  const openEdit = (v) => { setEditData({ ...v }); setModal(true) }
  const saveEdit = () => {
    setVideos(prev => prev.map(v => v.id === editData.id ? editData : v))
    setModal(false)
  }
  const toggleSelect = (id) => setSelected(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])
  const delSelected = () => {
    if (!selected.length) return alert('삭제할 항목을 선택하세요')
    if (confirm(`${selected.length}개를 삭제하시겠습니까?`)) { setVideos(prev => prev.filter(v => !selected.includes(v.id))); setSelected([]) }
  }

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        <div style={s.sf}><span style={s.sl}>카테고리</span>
          <select style={s.si} value={search.category} onChange={e => { setSearch(p => ({ ...p, category: e.target.value })); setPage(1) }}>
            {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        <div style={s.sf}><span style={s.sl}>제목</span>
          <input style={s.si} value={search.title} onChange={e => { setSearch(p => ({ ...p, title: e.target.value })); setPage(1) }} placeholder="동영상 제목" />
        </div>
        <div style={s.sf}><span style={s.sl}>노출</span>
          <select style={{ ...s.si, width: 100 }} value={search.visible} onChange={e => setSearch(p => ({ ...p, visible: e.target.value }))}>
            <option value="">전체</option><option value="Y">노출</option><option value="N">미노출</option>
          </select>
        </div>
        <button style={s.btnOutline} onClick={() => { setSearch({ category: '전체', title: '', visible: '' }); setPage(1) }}>초기화</button>
      </div>

      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{total}</b>개</span>
        <div style={s.headerBtns}>
          <select style={s.select} value={pageSize} onChange={e => { setPageSize(+e.target.value); setPage(1) }}>
            {[10, 20, 30].map(n => <option key={n} value={n}>{n}개씩</option>)}
          </select>
          <button style={{ ...s.btnOutline, color: '#e53e3e' }} onClick={delSelected}>선택 삭제</button>
          <button style={s.btnOutline}>📥 엑셀</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>
              <th style={s.th}><input type="checkbox" onChange={e => setSelected(e.target.checked ? paged.map(v => v.id) : [])} /></th>
              {['번호', '카테고리', '시리즈', '동영상 제목', '강사', '작성일', '노출', '추천', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}
            </tr>
          </thead>
          <tbody>
            {paged.map(v => (
              <tr key={v.id} style={styles.tr}>
                <td style={styles.td}><input type="checkbox" checked={selected.includes(v.id)} onChange={() => toggleSelect(v.id)} /></td>
                <td style={styles.td}>{v.id}</td>
                <td style={styles.td}><span style={styles.catBadge}>{v.category}</span></td>
                <td style={styles.td}><span style={styles.catBadge2}>{v.series}</span></td>
                <td style={{ ...styles.td, maxWidth: 220 }}><div style={styles.truncate}>{v.title}</div></td>
                <td style={styles.td}>{v.instructor}</td>
                <td style={styles.td}>{v.regDate}</td>
                <td style={styles.td}><span style={{ ...styles.badge, background: v.visible === 'Y' ? '#d1fae5' : '#f3f4f6', color: v.visible === 'Y' ? '#059669' : '#888' }}>{v.visible}</span></td>
                <td style={styles.td}><span style={{ ...styles.badge, background: v.recommended === 'Y' ? '#dbeafe' : '#f3f4f6', color: v.recommended === 'Y' ? '#1d4ed8' : '#888' }}>{v.recommended}</span></td>
                <td style={styles.td}><button style={styles.btnSm} onClick={() => openEdit(v)}>수정</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div style={s.pagination}>
        <button style={s.pageBtn} onClick={() => setPage(1)} disabled={page === 1}>{'<<'}</button>
        <button style={s.pageBtn} onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>{'<'}</button>
        {Array.from({ length: Math.min(5, totalPages) }, (_, i) => { const p = Math.max(1, page - 2) + i; return p <= totalPages ? <button key={p} style={{ ...s.pageBtn, ...(p === page ? s.pageBtnActive : {}) }} onClick={() => setPage(p)}>{p}</button> : null })}
        <button style={s.pageBtn} onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages}>{'>'}</button>
        <button style={s.pageBtn} onClick={() => setPage(totalPages)} disabled={page === totalPages}>{'>>'}</button>
        <span style={s.pageInfo}>{page} / {totalPages}</span>
      </div>

      {modal && editData && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>동영상 정보 수정</div>
            <div style={s.mFields}>
              <div style={s.mf}><label style={s.ml}>카테고리</label>
                <select style={s.mi} value={editData.category} onChange={e => setEditData(p => ({ ...p, category: e.target.value }))}>
                  {CATEGORIES.slice(1).map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              {[['제목', 'title'], ['강사', 'instructor'], ['해시태그', 'hashtags'], ['파일명', 'filename']].map(([label, key]) => (
                <div key={key} style={s.mf}><label style={s.ml}>{label}</label>
                  <input style={s.mi} value={editData[key] || ''} onChange={e => setEditData(p => ({ ...p, [key]: e.target.value }))} placeholder={label} />
                </div>
              ))}
              <div style={{ display: 'flex', gap: 12 }}>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>노출</label>
                  <select style={s.mi} value={editData.visible} onChange={e => setEditData(p => ({ ...p, visible: e.target.value }))}>
                    <option value="Y">노출</option><option value="N">미노출</option>
                  </select>
                </div>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>추천</label>
                  <select style={s.mi} value={editData.recommended} onChange={e => setEditData(p => ({ ...p, recommended: e.target.value }))}>
                    <option value="Y">Y</option><option value="N">N</option>
                  </select>
                </div>
              </div>
            </div>
            <div style={s.mbtn}>
              <button style={s.btnPrimary} onClick={saveEdit}>저장</button>
              <button style={s.btnOutline} onClick={() => setModal(false)}>취소</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

const s = {
  root: { display: 'flex', flexDirection: 'column', gap: 16 },
  searchBox: { background: '#fff', borderRadius: 12, padding: '16px 20px', display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  sf: { display: 'flex', alignItems: 'center', gap: 8 }, sl: { fontSize: 13, color: '#555', whiteSpace: 'nowrap', fontWeight: 600 },
  si: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, width: 140 },
  tableHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  total: { fontSize: 13, color: '#555' }, headerBtns: { display: 'flex', gap: 10, alignItems: 'center' },
  select: { padding: '7px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse', minWidth: 900 },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  pagination: { display: 'flex', gap: 6, alignItems: 'center', justifyContent: 'center' },
  pageBtn: { padding: '6px 12px', border: '1.5px solid #e5e7eb', borderRadius: 7, fontSize: 13, cursor: 'pointer', background: '#fff' },
  pageBtnActive: { background: '#4f46e5', color: '#fff', borderColor: '#4f46e5' },
  pageInfo: { fontSize: 13, color: '#888', marginLeft: 8 },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 480, boxShadow: '0 20px 60px rgba(0,0,0,0.2)', maxHeight: '80vh', overflowY: 'auto' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 24, color: '#1a1a2e' },
  mFields: { display: 'flex', flexDirection: 'column', gap: 14 }, mf: { display: 'flex', flexDirection: 'column', gap: 4 },
  ml: { fontSize: 12, color: '#666', fontWeight: 600 }, mi: { padding: '10px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  mbtn: { display: 'flex', gap: 10, marginTop: 24, justifyContent: 'flex-end' },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
}
const styles = {
  tr: { borderBottom: '1px solid #fafafa' }, td: { padding: '10px 12px', fontSize: 13, color: '#333' },
  catBadge: { background: '#f3f4f6', padding: '2px 8px', borderRadius: 6, fontSize: 11, color: '#555' },
  catBadge2: { background: '#ede9fe', padding: '2px 8px', borderRadius: 6, fontSize: 11, color: '#7c3aed' },
  badge: { padding: '3px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer' },
  truncate: { maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' },
}
