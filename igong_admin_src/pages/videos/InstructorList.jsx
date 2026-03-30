import { useState } from 'react'
import { mockInstructors } from '../../utils/mockData'

const emptyForm = { name: '', email: '', phone: '', address: '', visible: 'Y', note: '' }

export default function InstructorList() {
  const [search, setSearch] = useState({ name: '', visible: '' })
  const [instructors, setInstructors] = useState(mockInstructors)
  const [modal, setModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)

  const filtered = instructors.filter(i =>
    (!search.name || i.name.includes(search.name)) &&
    (!search.visible || i.visible === search.visible)
  )

  const openAdd = () => { setForm(emptyForm); setEditId(null); setModal(true) }
  const openEdit = (ins) => { setForm({ ...ins }); setEditId(ins.id); setModal(true) }
  const save = () => {
    if (!form.name) return alert('이름을 입력하세요')
    if (editId) {
      setInstructors(prev => prev.map(i => i.id === editId ? { ...form, id: editId } : i))
    } else {
      setInstructors(prev => [...prev, { ...form, id: Date.now(), regDate: new Date().toISOString().slice(0, 10) }])
    }
    setModal(false)
  }
  const del = (id) => { if (confirm('삭제하시겠습니까?')) setInstructors(prev => prev.filter(i => i.id !== id)) }

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        <div style={s.sf}>
          <span style={s.sl}>이름</span>
          <input style={s.si} value={search.name} onChange={e => setSearch(p => ({ ...p, name: e.target.value }))} placeholder="강사명 검색" />
        </div>
        <div style={s.sf}>
          <span style={s.sl}>노출</span>
          <select style={s.si} value={search.visible} onChange={e => setSearch(p => ({ ...p, visible: e.target.value }))}>
            <option value="">전체</option><option value="Y">노출</option><option value="N">미노출</option>
          </select>
        </div>
        <button style={s.btnOutline} onClick={() => setSearch({ name: '', visible: '' })}>초기화</button>
      </div>

      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{filtered.length}</b>명</span>
        <div style={s.headerBtns}>
          <button style={s.btnPrimary} onClick={openAdd}>+ 강사 추가</button>
          <button style={s.btnOutline} onClick={() => alert('엑셀 다운로드')}>📥 엑셀</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>{['번호', '이름', '이메일', '휴대폰', '등록일', '노출', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {filtered.map(ins => (
              <tr key={ins.id} style={s.tr}>
                <td style={s.td}>{ins.id}</td>
                <td style={s.td}><b>{ins.name}</b></td>
                <td style={s.td}>{ins.email}</td>
                <td style={s.td}>{ins.phone}</td>
                <td style={s.td}>{ins.regDate}</td>
                <td style={s.td}>
                  <span style={{ ...s.badge, background: ins.visible === 'Y' ? '#d1fae5' : '#f3f4f6', color: ins.visible === 'Y' ? '#059669' : '#888' }}>
                    {ins.visible === 'Y' ? '노출' : '미노출'}
                  </span>
                </td>
                <td style={s.td}>
                  <button style={s.btnSm} onClick={() => openEdit(ins)}>수정</button>
                  <button style={{ ...s.btnSm, ...s.btnDanger }} onClick={() => del(ins.id)}>삭제</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>{editId ? '강사 수정' : '강사 추가'}</div>
            <div style={s.mFields}>
              {[['이름', 'name'], ['이메일', 'email'], ['휴대폰', 'phone'], ['주소', 'address'], ['메모', 'note']].map(([label, key]) => (
                <div key={key} style={s.mf}>
                  <label style={s.ml}>{label}</label>
                  <input style={s.mi} value={form[key] || ''} onChange={e => setForm(p => ({ ...p, [key]: e.target.value }))} placeholder={label} />
                </div>
              ))}
              <div style={s.mf}>
                <label style={s.ml}>노출 여부</label>
                <select style={s.mi} value={form.visible} onChange={e => setForm(p => ({ ...p, visible: e.target.value }))}>
                  <option value="Y">노출</option><option value="N">미노출</option>
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
  sf: { display: 'flex', alignItems: 'center', gap: 8 },
  sl: { fontSize: 13, color: '#555', whiteSpace: 'nowrap', fontWeight: 600 },
  si: { padding: '8px 12px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, width: 140 },
  tableHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  total: { fontSize: 13, color: '#555' },
  headerBtns: { display: 'flex', gap: 10 },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse' },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  tr: { borderBottom: '1px solid #fafafa' },
  td: { padding: '10px 12px', fontSize: 13, color: '#333' },
  badge: { padding: '3px 10px', borderRadius: 20, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer', marginRight: 4 },
  btnDanger: { background: '#fff0f0', color: '#e53e3e' },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 460, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 24, color: '#1a1a2e' },
  mFields: { display: 'flex', flexDirection: 'column', gap: 14 },
  mf: { display: 'flex', flexDirection: 'column', gap: 4 },
  ml: { fontSize: 12, color: '#666', fontWeight: 600 },
  mi: { padding: '10px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  mbtn: { display: 'flex', gap: 10, marginTop: 24, justifyContent: 'flex-end' },
}
