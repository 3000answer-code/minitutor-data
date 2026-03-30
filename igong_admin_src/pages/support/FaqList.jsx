import { useState } from 'react'
import { mockFaqs } from '../../utils/mockData'

const FAQ_CATEGORIES = ['이용권', '계정', '강의', '결제', '기술문의', '기타']
const emptyForm = { category: '이용권', question: '', answer: '', visible: 'Y' }

export default function FaqList() {
  const [faqs, setFaqs] = useState(mockFaqs)
  const [search, setSearch] = useState({ category: '', question: '' })
  const [modal, setModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)
  const [selected, setSelected] = useState([])
  const [expanded, setExpanded] = useState(null)

  const filtered = faqs.filter(f =>
    (!search.category || f.category === search.category) &&
    (!search.question || f.question.includes(search.question))
  )

  const openAdd = () => { setForm(emptyForm); setEditId(null); setModal(true) }
  const openEdit = (f) => { setForm({ ...f }); setEditId(f.id); setModal(true) }
  const save = () => {
    if (!form.question) return alert('질문을 입력하세요')
    if (!form.answer) return alert('답변을 입력하세요')
    if (editId) setFaqs(prev => prev.map(f => f.id === editId ? { ...f, ...form } : f))
    else setFaqs(prev => [{ ...form, id: Date.now(), regDate: new Date().toISOString().slice(0, 10), views: 0 }, ...prev])
    setModal(false)
  }
  const delSelected = () => {
    if (!selected.length) return alert('삭제할 항목을 선택하세요')
    if (confirm(`${selected.length}개를 삭제하시겠습니까?`)) { setFaqs(prev => prev.filter(f => !selected.includes(f.id))); setSelected([]) }
  }
  const toggleSelect = (id) => setSelected(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        <div style={s.sf}><span style={s.sl}>카테고리</span>
          <select style={s.si} value={search.category} onChange={e => setSearch(p => ({ ...p, category: e.target.value }))}>
            <option value="">전체</option>
            {FAQ_CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        <div style={s.sf}><span style={s.sl}>질문</span>
          <input style={s.si} value={search.question} onChange={e => setSearch(p => ({ ...p, question: e.target.value }))} placeholder="질문 내용 검색" />
        </div>
        <button style={s.btnOutline} onClick={() => setSearch({ category: '', question: '' })}>초기화</button>
      </div>

      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{filtered.length}</b>건</span>
        <div style={s.headerBtns}>
          <button style={s.btnPrimary} onClick={openAdd}>+ FAQ 등록</button>
          <button style={{ ...s.btnOutline, color: '#e53e3e' }} onClick={delSelected}>선택 삭제</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>
              <th style={s.th}><input type="checkbox" onChange={e => setSelected(e.target.checked ? filtered.map(f => f.id) : [])} /></th>
              {['번호', '카테고리', '질문', '작성일', '노출', '조회', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}
            </tr>
          </thead>
          <tbody>
            {filtered.map(f => (
              <>
                <tr key={f.id} style={styles.tr}>
                  <td style={styles.td}><input type="checkbox" checked={selected.includes(f.id)} onChange={() => toggleSelect(f.id)} /></td>
                  <td style={styles.td}>{f.id}</td>
                  <td style={styles.td}><span style={styles.catBadge}>{f.category}</span></td>
                  <td style={{ ...styles.td, maxWidth: 300 }}>
                    <div style={styles.qRow} onClick={() => setExpanded(expanded === f.id ? null : f.id)}>
                      <span style={{ color: '#4f46e5', fontWeight: 700, marginRight: 8 }}>Q</span>
                      {f.question}
                      <span style={{ marginLeft: 'auto', fontSize: 11 }}>{expanded === f.id ? '▲' : '▼'}</span>
                    </div>
                  </td>
                  <td style={styles.td}>{f.regDate}</td>
                  <td style={styles.td}><span style={{ ...styles.badge, background: f.visible === 'Y' ? '#d1fae5' : '#f3f4f6', color: f.visible === 'Y' ? '#059669' : '#888' }}>{f.visible}</span></td>
                  <td style={styles.td}>{f.views}</td>
                  <td style={styles.td}><button style={styles.btnSm} onClick={() => openEdit(f)}>수정</button></td>
                </tr>
                {expanded === f.id && (
                  <tr key={`ans-${f.id}`}>
                    <td colSpan={9} style={styles.answerCell}>
                      <span style={{ color: '#059669', fontWeight: 700, marginRight: 8 }}>A</span>
                      {f.answer}
                    </td>
                  </tr>
                )}
              </>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>{editId ? 'FAQ 수정' : 'FAQ 등록'}</div>
            <div style={s.mFields}>
              <div style={s.mf}><label style={s.ml}>카테고리</label>
                <select style={s.mi} value={form.category} onChange={e => setForm(p => ({ ...p, category: e.target.value }))}>
                  {FAQ_CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div style={s.mf}><label style={s.ml}>질문</label>
                <input style={s.mi} value={form.question} onChange={e => setForm(p => ({ ...p, question: e.target.value }))} placeholder="질문을 입력하세요" />
              </div>
              <div style={s.mf}><label style={s.ml}>답변</label>
                <textarea style={{ ...s.mi, height: 150, resize: 'vertical' }} value={form.answer} onChange={e => setForm(p => ({ ...p, answer: e.target.value }))} placeholder="답변을 입력하세요..." />
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
  si: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, width: 160 },
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
  catBadge: { background: '#f3f4f6', padding: '2px 8px', borderRadius: 6, fontSize: 11, color: '#555' },
  qRow: { display: 'flex', alignItems: 'center', cursor: 'pointer', fontWeight: 600, gap: 4 },
  badge: { padding: '3px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer' },
  answerCell: { padding: '12px 20px 16px 48px', background: '#f8fffe', fontSize: 13, color: '#333', lineHeight: 1.7, borderBottom: '1px solid #e8f5f0' },
}
