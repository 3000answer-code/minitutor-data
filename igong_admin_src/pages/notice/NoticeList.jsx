import { useState } from 'react'
import { mockNotices } from '../../utils/mockData'

const emptyForm = { title: '', content: '', visible: 'Y', recommended: 'N' }

export default function NoticeList() {
  const [notices, setNotices] = useState(mockNotices)
  const [search, setSearch] = useState({ title: '', visible: '' })
  const [modal, setModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)
  const [selected, setSelected] = useState([])

  const filtered = notices.filter(n =>
    (!search.title || n.title.includes(search.title)) &&
    (!search.visible || n.visible === search.visible)
  )

  const openAdd = () => { setForm(emptyForm); setEditId(null); setModal(true) }
  const openEdit = (n) => { setForm({ ...n }); setEditId(n.id); setModal(true) }
  const save = () => {
    if (!form.title) return alert('제목을 입력하세요')
    if (editId) setNotices(prev => prev.map(n => n.id === editId ? { ...n, ...form } : n))
    else setNotices(prev => [{ ...form, id: Date.now(), regDate: new Date().toISOString().slice(0, 10), views: 0 }, ...prev])
    setModal(false)
  }
  const delSelected = () => {
    if (!selected.length) return alert('삭제할 항목을 선택하세요')
    if (confirm(`${selected.length}개를 삭제하시겠습니까?`)) { setNotices(prev => prev.filter(n => !selected.includes(n.id))); setSelected([]) }
  }
  const toggleSelect = (id) => setSelected(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        <div style={s.sf}><span style={s.sl}>제목</span>
          <input style={s.si} value={search.title} onChange={e => setSearch(p => ({ ...p, title: e.target.value }))} placeholder="공지 제목 검색" />
        </div>
        <div style={s.sf}><span style={s.sl}>노출</span>
          <select style={{ ...s.si, width: 120 }} value={search.visible} onChange={e => setSearch(p => ({ ...p, visible: e.target.value }))}>
            <option value="">전체</option><option value="Y">노출</option><option value="N">미노출</option>
          </select>
        </div>
        <button style={s.btnOutline} onClick={() => setSearch({ title: '', visible: '' })}>초기화</button>
      </div>

      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{filtered.length}</b>건</span>
        <div style={s.headerBtns}>
          <button style={s.btnPrimary} onClick={openAdd}>+ 공지 등록</button>
          <button style={{ ...s.btnOutline, color: '#e53e3e' }} onClick={delSelected}>선택 삭제</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>
              <th style={s.th}><input type="checkbox" onChange={e => setSelected(e.target.checked ? filtered.map(n => n.id) : [])} /></th>
              {['번호', '제목', '작성일', '노출', '조회', '추천', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}
            </tr>
          </thead>
          <tbody>
            {filtered.map(n => (
              <tr key={n.id} style={styles.tr}>
                <td style={styles.td}><input type="checkbox" checked={selected.includes(n.id)} onChange={() => toggleSelect(n.id)} /></td>
                <td style={styles.td}>{n.id}</td>
                <td style={{ ...styles.td, maxWidth: 300 }}>
                  <div style={styles.titleLink} onClick={() => openEdit(n)}>{n.title}</div>
                </td>
                <td style={styles.td}>{n.regDate}</td>
                <td style={styles.td}><span style={{ ...styles.badge, background: n.visible === 'Y' ? '#d1fae5' : '#f3f4f6', color: n.visible === 'Y' ? '#059669' : '#888' }}>{n.visible}</span></td>
                <td style={styles.td}>{n.views?.toLocaleString()}</td>
                <td style={styles.td}><span style={{ ...styles.badge, background: n.recommended === 'Y' ? '#dbeafe' : '#f3f4f6', color: n.recommended === 'Y' ? '#1d4ed8' : '#888' }}>{n.recommended}</span></td>
                <td style={styles.td}>
                  <button style={styles.btnSm} onClick={() => openEdit(n)}>수정</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>{editId ? '공지 수정' : '공지 등록'}</div>
            <div style={s.mFields}>
              <div style={s.mf}><label style={s.ml}>제목</label>
                <input style={s.mi} value={form.title} onChange={e => setForm(p => ({ ...p, title: e.target.value }))} placeholder="공지 제목" />
              </div>
              <div style={s.mf}><label style={s.ml}>내용</label>
                <textarea style={{ ...s.mi, height: 200, resize: 'vertical' }} value={form.content} onChange={e => setForm(p => ({ ...p, content: e.target.value }))} placeholder="내용을 입력하세요..." />
              </div>
              <div style={{ display: 'flex', gap: 16 }}>
                {[['노출', 'visible', ['Y', 'N']], ['추천(메인노출)', 'recommended', ['Y', 'N']]].map(([label, key, opts]) => (
                  <div key={key} style={{ ...s.mf, flex: 1 }}><label style={s.ml}>{label}</label>
                    <select style={s.mi} value={form[key]} onChange={e => setForm(p => ({ ...p, [key]: e.target.value }))}>
                      {opts.map(o => <option key={o} value={o}>{o}</option>)}
                    </select>
                  </div>
                ))}
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
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 580, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
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
  titleLink: { fontWeight: 600, color: '#1a1a2e', cursor: 'pointer' },
  badge: { padding: '3px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer' },
}
