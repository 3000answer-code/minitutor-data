import { useState } from 'react'
import { mockAdmins } from '../../utils/mockData'

const PERM_LABELS = {
  members: '회원관리',
  videos: '동영상백과',
  consult: '전문가상담',
  notice: '공지사항',
  support: '고객센터',
  coupon: '쿠폰관리',
  admin: '기타관리',
}
const ALL_PERMS = Object.keys(PERM_LABELS)

const emptyForm = { name: '', userId: '', password: '', permissions: [] }

export default function AdminList() {
  const [admins, setAdmins] = useState(mockAdmins)
  const [modal, setModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)

  const openAdd = () => { setForm(emptyForm); setEditId(null); setModal(true) }
  const openEdit = (a) => { setForm({ ...a, password: '' }); setEditId(a.id); setModal(true) }
  const togglePerm = (p) => {
    setForm(prev => ({
      ...prev,
      permissions: prev.permissions.includes(p) ? prev.permissions.filter(x => x !== p) : [...prev.permissions, p]
    }))
  }
  const save = () => {
    if (!form.name) return alert('이름을 입력하세요')
    if (!editId && !form.userId) return alert('아이디를 입력하세요')
    if (editId) setAdmins(prev => prev.map(a => a.id === editId ? { ...a, name: form.name, permissions: form.permissions } : a))
    else setAdmins(prev => [...prev, { ...form, id: Date.now() }])
    setModal(false)
  }
  const del = (id) => { if (confirm('관리자를 삭제하시겠습니까?')) setAdmins(prev => prev.filter(a => a.id !== id)) }

  return (
    <div style={s.root}>
      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{admins.length}</b>명</span>
        <button style={s.btnPrimary} onClick={openAdd}>+ 관리자 추가</button>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>{['번호', '이름', '아이디', '권한', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}</tr>
          </thead>
          <tbody>
            {admins.map(a => (
              <tr key={a.id} style={styles.tr}>
                <td style={styles.td}>{a.id}</td>
                <td style={styles.td}><b>{a.name}</b></td>
                <td style={styles.td}>{a.userId}</td>
                <td style={{ ...styles.td, maxWidth: 400 }}>
                  <div style={styles.permList}>
                    {a.permissions.includes('members') && a.permissions.includes('videos') && a.permissions.includes('admin') ? (
                      <span style={styles.permBadgeSuperAdmin}>슈퍼관리자 (전체)</span>
                    ) : (
                      a.permissions.map(p => (
                        <span key={p} style={styles.permBadge}>{PERM_LABELS[p]}</span>
                      ))
                    )}
                  </div>
                </td>
                <td style={styles.td}>
                  <button style={styles.btnSm} onClick={() => openEdit(a)}>수정</button>
                  <button style={{ ...styles.btnSm, ...styles.btnDanger }} onClick={() => del(a.id)}>삭제</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>{editId ? '관리자 수정' : '관리자 추가'}</div>
            <div style={s.mFields}>
              <div style={s.mf}><label style={s.ml}>이름</label>
                <input style={s.mi} value={form.name} onChange={e => setForm(p => ({ ...p, name: e.target.value }))} placeholder="관리자 이름" />
              </div>
              {!editId && (
                <div style={s.mf}><label style={s.ml}>아이디</label>
                  <input style={s.mi} value={form.userId} onChange={e => setForm(p => ({ ...p, userId: e.target.value }))} placeholder="로그인 아이디" />
                </div>
              )}
              <div style={s.mf}><label style={s.ml}>비밀번호 {editId ? '(변경시에만 입력)' : ''}</label>
                <input type="password" style={s.mi} value={form.password} onChange={e => setForm(p => ({ ...p, password: e.target.value }))} placeholder="비밀번호" />
              </div>
              <div style={s.mf}>
                <label style={s.ml}>권한 설정</label>
                <div style={s.permGrid}>
                  {ALL_PERMS.map(p => (
                    <label key={p} style={s.permItem}>
                      <input type="checkbox" checked={form.permissions.includes(p)} onChange={() => togglePerm(p)} />
                      <span>{PERM_LABELS[p]}</span>
                    </label>
                  ))}
                </div>
                <div style={{ marginTop: 8 }}>
                  <button style={s.btnSmAll} onClick={() => setForm(prev => ({ ...prev, permissions: ALL_PERMS }))}>전체 선택</button>
                  <button style={{ ...s.btnSmAll, marginLeft: 8 }} onClick={() => setForm(prev => ({ ...prev, permissions: [] }))}>전체 해제</button>
                </div>
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
  tableHeader: { display: 'flex', alignItems: 'center', justifyContent: 'space-between' },
  total: { fontSize: 13, color: '#555' },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse' },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 480, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
  modalTitle: { fontSize: 18, fontWeight: 700, marginBottom: 20, color: '#1a1a2e' },
  mFields: { display: 'flex', flexDirection: 'column', gap: 14 },
  mf: { display: 'flex', flexDirection: 'column', gap: 6 }, ml: { fontSize: 12, color: '#666', fontWeight: 600 },
  mi: { padding: '10px 14px', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13 },
  permGrid: { display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 8, background: '#f8f9fa', borderRadius: 8, padding: 16 },
  permItem: { display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: 13, color: '#444' },
  mbtn: { display: 'flex', gap: 10, marginTop: 24, justifyContent: 'flex-end' },
  btnSmAll: { padding: '4px 12px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer' },
  btnPrimary: { padding: '8px 18px', background: 'linear-gradient(135deg, #4f46e5, #7c3aed)', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer' },
  btnOutline: { padding: '8px 18px', background: '#fff', border: '1.5px solid #e5e7eb', borderRadius: 8, fontSize: 13, cursor: 'pointer' },
}
const styles = {
  tr: { borderBottom: '1px solid #fafafa' }, td: { padding: '12px 12px', fontSize: 13, color: '#333' },
  permList: { display: 'flex', flexWrap: 'wrap', gap: 6 },
  permBadge: { background: '#ede9fe', color: '#7c3aed', padding: '3px 8px', borderRadius: 6, fontSize: 11, fontWeight: 600 },
  permBadgeSuperAdmin: { background: '#1a1a2e', color: '#fff', padding: '3px 12px', borderRadius: 6, fontSize: 11, fontWeight: 700 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer', marginRight: 4 },
  btnDanger: { background: '#fff0f0', color: '#e53e3e' },
}
