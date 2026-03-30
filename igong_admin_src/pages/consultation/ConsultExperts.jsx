import { useState } from 'react'
import { mockMembers } from '../../utils/mockData'

const initExperts = mockMembers.slice(0, 5).map((m, i) => ({
  ...m,
  type: ['수학', '영어', '과학', '국어', '사회'][i],
  permission: 'Y',
  visible: 'Y',
  image: '',
  intro: '안녕하세요. 전문 강사입니다.',
}))

const emptyForm = { name: '', userId: '', password: '', nickname: '', email: '', phone: '', address: '', type: '수학', permission: 'Y', visible: 'Y', intro: '' }

export default function ConsultExperts() {
  const [experts, setExperts] = useState(initExperts)
  const [search, setSearch] = useState({ name: '', visible: '' })
  const [modal, setModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)

  const filtered = experts.filter(e =>
    (!search.name || e.name.includes(search.name)) &&
    (!search.visible || e.visible === search.visible)
  )

  const openAdd = () => { setForm(emptyForm); setEditId(null); setModal(true) }
  const openEdit = (e) => { setForm({ ...e }); setEditId(e.id); setModal(true) }
  const save = () => {
    if (!form.name) return alert('이름을 입력하세요')
    if (editId) setExperts(prev => prev.map(e => e.id === editId ? { ...form, id: editId } : e))
    else setExperts(prev => [...prev, { ...form, id: Date.now(), joinDate: new Date().toISOString().slice(0, 10) }])
    setModal(false)
  }
  const del = (id) => { if (confirm('삭제하시겠습니까?')) setExperts(prev => prev.filter(e => e.id !== id)) }

  return (
    <div style={s.root}>
      <div style={s.searchBox}>
        <div style={s.sf}><span style={s.sl}>이름</span>
          <input style={s.si} value={search.name} onChange={e => setSearch(p => ({ ...p, name: e.target.value }))} placeholder="전문가 이름" />
        </div>
        <div style={s.sf}><span style={s.sl}>노출</span>
          <select style={{ ...s.si, width: 120 }} value={search.visible} onChange={e => setSearch(p => ({ ...p, visible: e.target.value }))}>
            <option value="">전체</option><option value="Y">노출</option><option value="N">미노출</option>
          </select>
        </div>
        <button style={s.btnOutline} onClick={() => setSearch({ name: '', visible: '' })}>초기화</button>
      </div>

      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{filtered.length}</b>명</span>
        <div style={s.headerBtns}>
          <button style={s.btnPrimary} onClick={openAdd}>+ 전문가 추가</button>
          <button style={s.btnOutline}>📥 엑셀</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>{['번호', '이름', '아이디', '닉네임', '휴대폰', '분야', '등록일', '권한', '노출', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {filtered.map(e => (
              <tr key={e.id} style={styles.tr}>
                <td style={styles.td}>{e.id}</td>
                <td style={styles.td}><b>{e.name}</b></td>
                <td style={styles.td}>{e.userId}</td>
                <td style={styles.td}>{e.nickname}</td>
                <td style={styles.td}>{e.phone}</td>
                <td style={styles.td}><span style={styles.typeBadge}>{e.type}</span></td>
                <td style={styles.td}>{e.joinDate}</td>
                <td style={styles.td}><span style={{ ...styles.badge, background: '#d1fae5', color: '#059669' }}>{e.permission === 'Y' ? '활성' : '비활성'}</span></td>
                <td style={styles.td}><span style={{ ...styles.badge, background: e.visible === 'Y' ? '#dbeafe' : '#f3f4f6', color: e.visible === 'Y' ? '#1d4ed8' : '#888' }}>{e.visible}</span></td>
                <td style={styles.td}>
                  <button style={styles.btnSm} onClick={() => openEdit(e)}>수정</button>
                  <button style={styles.btnSm} onClick={() => alert('대리로그인: ' + e.userId)}>대리로그인</button>
                  <button style={{ ...styles.btnSm, ...styles.btnDanger }} onClick={() => del(e.id)}>삭제</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>{editId ? '전문가 수정' : '전문가 추가'}</div>
            <div style={s.mGrid}>
              {[['이름', 'name'], ['아이디', 'userId'], ['비밀번호', 'password'], ['닉네임', 'nickname'], ['이메일', 'email'], ['휴대폰', 'phone']].map(([label, key]) => (
                <div key={key} style={s.mf}><label style={s.ml}>{label}</label>
                  <input style={s.mi} value={form[key] || ''} type={key === 'password' ? 'password' : 'text'}
                    onChange={e => setForm(p => ({ ...p, [key]: e.target.value }))} placeholder={label} />
                </div>
              ))}
            </div>
            <div style={s.mf}><label style={s.ml}>주소</label>
              <input style={s.mi} value={form.address || ''} onChange={e => setForm(p => ({ ...p, address: e.target.value }))} placeholder="주소" />
            </div>
            <div style={s.mf}><label style={s.ml}>소개</label>
              <textarea style={{ ...s.mi, height: 80, resize: 'vertical' }} value={form.intro || ''} onChange={e => setForm(p => ({ ...p, intro: e.target.value }))} />
            </div>
            <div style={{ display: 'flex', gap: 12, marginTop: 4 }}>
              {[['분야', 'type', ['수학', '영어', '과학', '국어', '사회', '기타']], ['권한', 'permission', ['Y', 'N']], ['노출', 'visible', ['Y', 'N']]].map(([label, key, opts]) => (
                <div key={key} style={{ ...s.mf, flex: 1 }}><label style={s.ml}>{label}</label>
                  <select style={s.mi} value={form[key]} onChange={e => setForm(p => ({ ...p, [key]: e.target.value }))}>
                    {opts.map(o => <option key={o} value={o}>{o}</option>)}
                  </select>
                </div>
              ))}
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
  table: { width: '100%', borderCollapse: 'collapse', minWidth: 900 },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 560, boxShadow: '0 20px 60px rgba(0,0,0,0.2)', maxHeight: '85vh', overflowY: 'auto' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 20, color: '#1a1a2e' },
  mGrid: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 },
  mf: { display: 'flex', flexDirection: 'column', gap: 4, marginBottom: 12 },
  ml: { fontSize: 12, color: '#666', fontWeight: 600 }, mi: { padding: '10px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  mbtn: { display: 'flex', gap: 10, marginTop: 12, justifyContent: 'flex-end' },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
}
const styles = {
  tr: { borderBottom: '1px solid #fafafa' }, td: { padding: '10px 12px', fontSize: 13, color: '#333' },
  typeBadge: { background: '#f3e8ff', padding: '2px 8px', borderRadius: 6, fontSize: 11, color: '#7c3aed' },
  badge: { padding: '3px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer', marginRight: 4 },
  btnDanger: { background: '#fff0f0', color: '#e53e3e' },
}
