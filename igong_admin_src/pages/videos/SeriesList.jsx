import { useState } from 'react'
import { mockSeries } from '../../utils/mockData'

const CATEGORIES = ['전체', '수학/중등', '수학/고등', '영어/중등', '영어/고등', '과학/중등', '과학/고등', '국어/중등', '국어/고등', '사회/중등', '사회/고등', '기타']
const emptyForm = { category: '수학/중등', title: '', visible: 'Y', recommended: 'N' }

export default function SeriesList() {
  const [search, setSearch] = useState({ category: '전체', title: '' })
  const [series, setSeries] = useState(mockSeries)
  const [modal, setModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)
  const [selected, setSelected] = useState([])

  const filtered = series.filter(s =>
    (search.category === '전체' || s.category === search.category) &&
    (!search.title || s.title.includes(search.title))
  )

  const toggleSelect = (id) => setSelected(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])
  const openAdd = () => { setForm(emptyForm); setEditId(null); setModal(true) }
  const openEdit = (s) => { setForm({ ...s }); setEditId(s.id); setModal(true) }
  const save = () => {
    if (!form.title) return alert('제목을 입력하세요')
    if (editId) {
      setSeries(prev => prev.map(s => s.id === editId ? { ...form, id: editId, count: s.count } : s))
    } else {
      setSeries(prev => [...prev, { ...form, id: Date.now(), count: 0, regDate: new Date().toISOString().slice(0, 10) }])
    }
    setModal(false)
  }
  const delSelected = () => {
    if (!selected.length) return alert('삭제할 항목을 선택하세요')
    if (confirm(`${selected.length}개를 삭제하시겠습니까?`)) {
      setSeries(prev => prev.filter(s => !selected.includes(s.id)))
      setSelected([])
    }
  }

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        <div style={s.sf}>
          <span style={s.sl}>카테고리</span>
          <select style={s.si} value={search.category} onChange={e => setSearch(p => ({ ...p, category: e.target.value }))}>
            {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        <div style={s.sf}>
          <span style={s.sl}>제목</span>
          <input style={s.si} value={search.title} onChange={e => setSearch(p => ({ ...p, title: e.target.value }))} placeholder="시리즈 제목 검색" />
        </div>
        <button style={s.btnOutline} onClick={() => setSearch({ category: '전체', title: '' })}>초기화</button>
      </div>

      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{filtered.length}</b>건</span>
        <div style={s.headerBtns}>
          <button style={s.btnPrimary} onClick={openAdd}>+ 시리즈 추가</button>
          <button style={{ ...s.btnOutline, color: '#e53e3e' }} onClick={delSelected}>선택 삭제</button>
          <button style={s.btnOutline}>📥 엑셀</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>
              <th style={s.th}><input type="checkbox" onChange={e => setSelected(e.target.checked ? filtered.map(s => s.id) : [])} /></th>
              {['번호', '카테고리', '시리즈 제목', '동영상수', '노출', '추천', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}
            </tr>
          </thead>
          <tbody>
            {filtered.map(s => (
              <tr key={s.id} style={styles.tr}>
                <td style={styles.td}><input type="checkbox" checked={selected.includes(s.id)} onChange={() => toggleSelect(s.id)} /></td>
                <td style={styles.td}>{s.id}</td>
                <td style={styles.td}><span style={styles.catBadge}>{s.category}</span></td>
                <td style={styles.td}><b>{s.title}</b></td>
                <td style={styles.td}>{s.count}개</td>
                <td style={styles.td}>
                  <span style={{ ...styles.badge, background: s.visible === 'Y' ? '#d1fae5' : '#f3f4f6', color: s.visible === 'Y' ? '#059669' : '#888' }}>{s.visible === 'Y' ? 'Y' : 'N'}</span>
                </td>
                <td style={styles.td}>
                  <span style={{ ...styles.badge, background: s.recommended === 'Y' ? '#dbeafe' : '#f3f4f6', color: s.recommended === 'Y' ? '#1d4ed8' : '#888' }}>{s.recommended === 'Y' ? 'Y' : 'N'}</span>
                </td>
                <td style={styles.td}>
                  <button style={styles.btnSm} onClick={() => openEdit(s)}>수정</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>{editId ? '시리즈 수정' : '시리즈 추가'}</div>
            <div style={s.mFields}>
              <div style={s.mf}><label style={s.ml}>카테고리</label>
                <select style={s.mi} value={form.category} onChange={e => setForm(p => ({ ...p, category: e.target.value }))}>
                  {CATEGORIES.slice(1).map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div style={s.mf}><label style={s.ml}>시리즈 제목</label>
                <input style={s.mi} value={form.title} onChange={e => setForm(p => ({ ...p, title: e.target.value }))} placeholder="시리즈 제목" />
              </div>
              <div style={s.mf}><label style={s.ml}>노출</label>
                <select style={s.mi} value={form.visible} onChange={e => setForm(p => ({ ...p, visible: e.target.value }))}>
                  <option value="Y">노출</option><option value="N">미노출</option>
                </select>
              </div>
              <div style={s.mf}><label style={s.ml}>추천</label>
                <select style={s.mi} value={form.recommended} onChange={e => setForm(p => ({ ...p, recommended: e.target.value }))}>
                  <option value="Y">Y</option><option value="N">N</option>
                </select>
              </div>
            </div>
            <div style={s.mbtn}>
              <button style={s.btnPrimary} onClick={save}>저장</button>
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
  si: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, width: 160 },
  tableHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  total: { fontSize: 13, color: '#555' }, headerBtns: { display: 'flex', gap: 10 },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse' },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 440, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
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
  badge: { padding: '3px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer' },
}
