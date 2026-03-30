import { useState } from 'react'
import { mockEvents } from '../../utils/mockData'

const CATEGORIES = ['이벤트', '행사', '공모전', '프로모션']
const emptyForm = { category: '이벤트', title: '', periodFrom: '', periodTo: '', content: '', visible: 'Y' }

export default function EventList() {
  const [events, setEvents] = useState(mockEvents)
  const [search, setSearch] = useState({ category: '', title: '' })
  const [modal, setModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)
  const [selected, setSelected] = useState([])

  const filtered = events.filter(e =>
    (!search.category || e.category === search.category) &&
    (!search.title || e.title.includes(search.title))
  )

  const openAdd = () => { setForm(emptyForm); setEditId(null); setModal(true) }
  const openEdit = (e) => { setForm({ ...e, periodFrom: e.period?.split(' ~ ')[0] || '', periodTo: e.period?.split(' ~ ')[1] || '' }); setEditId(e.id); setModal(true) }
  const save = () => {
    if (!form.title) return alert('제목을 입력하세요')
    const period = `${form.periodFrom} ~ ${form.periodTo}`
    if (editId) setEvents(prev => prev.map(e => e.id === editId ? { ...e, ...form, period } : e))
    else setEvents(prev => [{ ...form, id: Date.now(), period, regDate: new Date().toISOString().slice(0, 10), views: 0 }, ...prev])
    setModal(false)
  }
  const delSelected = () => {
    if (!selected.length) return alert('삭제할 항목을 선택하세요')
    if (confirm(`${selected.length}개를 삭제하시겠습니까?`)) { setEvents(prev => prev.filter(e => !selected.includes(e.id))); setSelected([]) }
  }
  const toggleSelect = (id) => setSelected(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        <div style={s.sf}><span style={s.sl}>카테고리</span>
          <select style={s.si} value={search.category} onChange={e => setSearch(p => ({ ...p, category: e.target.value }))}>
            <option value="">전체</option>
            {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        <div style={s.sf}><span style={s.sl}>제목</span>
          <input style={s.si} value={search.title} onChange={e => setSearch(p => ({ ...p, title: e.target.value }))} placeholder="이벤트 제목 검색" />
        </div>
        <button style={s.btnOutline} onClick={() => setSearch({ category: '', title: '' })}>초기화</button>
      </div>

      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{filtered.length}</b>건</span>
        <div style={s.headerBtns}>
          <button style={s.btnPrimary} onClick={openAdd}>+ 이벤트 등록</button>
          <button style={{ ...s.btnOutline, color: '#e53e3e' }} onClick={delSelected}>선택 삭제</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>
              <th style={s.th}><input type="checkbox" onChange={e => setSelected(e.target.checked ? filtered.map(ev => ev.id) : [])} /></th>
              {['번호', '카테고리', '기간', '제목', '작성일', '노출', '조회', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}
            </tr>
          </thead>
          <tbody>
            {filtered.map(ev => (
              <tr key={ev.id} style={styles.tr}>
                <td style={styles.td}><input type="checkbox" checked={selected.includes(ev.id)} onChange={() => toggleSelect(ev.id)} /></td>
                <td style={styles.td}>{ev.id}</td>
                <td style={styles.td}><span style={styles.catBadge}>{ev.category}</span></td>
                <td style={styles.td}>{ev.period}</td>
                <td style={{ ...styles.td, maxWidth: 220 }}>
                  <div style={styles.titleLink} onClick={() => openEdit(ev)}>{ev.title}</div>
                </td>
                <td style={styles.td}>{ev.regDate}</td>
                <td style={styles.td}><span style={{ ...styles.badge, background: ev.visible === 'Y' ? '#d1fae5' : '#f3f4f6', color: ev.visible === 'Y' ? '#059669' : '#888' }}>{ev.visible}</span></td>
                <td style={styles.td}>{ev.views?.toLocaleString()}</td>
                <td style={styles.td}><button style={styles.btnSm} onClick={() => openEdit(ev)}>수정</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>{editId ? '이벤트 수정' : '이벤트 등록'}</div>
            <div style={s.mFields}>
              <div style={s.mf}><label style={s.ml}>카테고리</label>
                <select style={s.mi} value={form.category} onChange={e => setForm(p => ({ ...p, category: e.target.value }))}>
                  {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div style={s.mf}><label style={s.ml}>제목</label>
                <input style={s.mi} value={form.title} onChange={e => setForm(p => ({ ...p, title: e.target.value }))} placeholder="이벤트 제목" />
              </div>
              <div style={{ display: 'flex', gap: 12 }}>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>시작일</label>
                  <input type="date" style={s.mi} value={form.periodFrom} onChange={e => setForm(p => ({ ...p, periodFrom: e.target.value }))} />
                </div>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>종료일</label>
                  <input type="date" style={s.mi} value={form.periodTo} onChange={e => setForm(p => ({ ...p, periodTo: e.target.value }))} />
                </div>
              </div>
              <div style={s.mf}><label style={s.ml}>내용 (이미지 URL or HTML)</label>
                <textarea style={{ ...s.mi, height: 120, resize: 'vertical' }} value={form.content} onChange={e => setForm(p => ({ ...p, content: e.target.value }))} placeholder="내용을 입력하세요..." />
              </div>
              <div style={s.mf}><label style={s.ml}>노출</label>
                <select style={s.mi} value={form.visible} onChange={e => setForm(p => ({ ...p, visible: e.target.value }))}>
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
  si: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, width: 140 },
  tableHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  total: { fontSize: 13, color: '#555' }, headerBtns: { display: 'flex', gap: 10 },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse' },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 560, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 20, color: '#1a1a2e' },
  mFields: { display: 'flex', flexDirection: 'column', gap: 14 },
  mf: { display: 'flex', flexDirection: 'column', gap: 4 }, ml: { fontSize: 12, color: '#666', fontWeight: 600 },
  mi: { padding: '10px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  mbtn: { display: 'flex', gap: 10, marginTop: 24, justifyContent: 'flex-end' },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
}
const styles = {
  tr: { borderBottom: '1px solid #fafafa' }, td: { padding: '10px 12px', fontSize: 13, color: '#333' },
  catBadge: { background: '#fff7ed', padding: '2px 8px', borderRadius: 6, fontSize: 11, color: '#d97706' },
  titleLink: { fontWeight: 600, color: '#1a1a2e', cursor: 'pointer' },
  badge: { padding: '3px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer' },
}
