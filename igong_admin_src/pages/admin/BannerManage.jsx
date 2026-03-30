import { useState } from 'react'
import { mockBanners } from '../../utils/mockData'

const emptyForm = { title: '', url: '', mobileUrl: '', imageUrl: '', order: 1, visible: 'Y' }

export default function BannerManage() {
  const [banners, setBanners] = useState(mockBanners)
  const [modal, setModal] = useState(false)
  const [form, setForm] = useState(emptyForm)
  const [editId, setEditId] = useState(null)
  const [selected, setSelected] = useState([])

  const openAdd = () => { setForm(emptyForm); setEditId(null); setModal(true) }
  const openEdit = (b) => { setForm({ ...b }); setEditId(b.id); setModal(true) }
  const save = () => {
    if (!form.title) return alert('제목을 입력하세요')
    if (editId) setBanners(prev => prev.map(b => b.id === editId ? { ...b, ...form } : b))
    else setBanners(prev => [...prev, { ...form, id: Date.now(), regDate: new Date().toISOString().slice(0, 10) }])
    setModal(false)
  }
  const del = (id) => { if (confirm('삭제하시겠습니까?')) setBanners(prev => prev.filter(b => b.id !== id)) }
  const delSelected = () => {
    if (!selected.length) return alert('삭제할 항목을 선택하세요')
    if (confirm(`${selected.length}개를 삭제하시겠습니까?`)) { setBanners(prev => prev.filter(b => !selected.includes(b.id))); setSelected([]) }
  }
  const toggleSelect = (id) => setSelected(p => p.includes(id) ? p.filter(x => x !== id) : [...p, id])

  return (
    <div style={s.root}>
      <div style={s.tableHeader}>
        <span style={s.total}>총 <b>{banners.length}</b>개</span>
        <div style={s.headerBtns}>
          <button style={s.btnPrimary} onClick={openAdd}>+ 배너 추가</button>
          <button style={{ ...s.btnOutline, color: '#e53e3e' }} onClick={delSelected}>선택 삭제</button>
        </div>
      </div>

      <div style={s.tableWrap}>
        <table style={s.table}>
          <thead>
            <tr>
              <th style={s.th}><input type="checkbox" onChange={e => setSelected(e.target.checked ? banners.map(b => b.id) : [])} /></th>
              {['번호', '제목', '웹 URL', '등록일', '노출', '순서', '관리'].map(h => <th key={h} style={s.th}>{h}</th>)}
            </tr>
          </thead>
          <tbody>
            {banners.map((b, idx) => (
              <tr key={b.id} style={styles.tr}>
                <td style={styles.td}><input type="checkbox" checked={selected.includes(b.id)} onChange={() => toggleSelect(b.id)} /></td>
                <td style={styles.td}>{b.id}</td>
                <td style={styles.td}><b>{b.title}</b></td>
                <td style={styles.td}><a href={b.url} style={{ color: '#4f46e5', fontSize: 12 }}>{b.url}</a></td>
                <td style={styles.td}>{b.regDate}</td>
                <td style={styles.td}><span style={{ ...styles.badge, background: b.visible === 'Y' ? '#d1fae5' : '#f3f4f6', color: b.visible === 'Y' ? '#059669' : '#888' }}>{b.visible}</span></td>
                <td style={styles.td}>
                  <div style={styles.orderBtns}>
                    <button style={styles.orderBtn} onClick={() => {
                      if (idx === 0) return
                      const newBanners = [...banners]; [newBanners[idx - 1], newBanners[idx]] = [newBanners[idx], newBanners[idx - 1]]; setBanners(newBanners)
                    }}>▲</button>
                    <button style={styles.orderBtn} onClick={() => {
                      if (idx === banners.length - 1) return
                      const newBanners = [...banners]; [newBanners[idx], newBanners[idx + 1]] = [newBanners[idx + 1], newBanners[idx]]; setBanners(newBanners)
                    }}>▼</button>
                  </div>
                </td>
                <td style={styles.td}>
                  <button style={styles.btnSm} onClick={() => openEdit(b)}>수정</button>
                  <button style={{ ...styles.btnSm, ...styles.btnDanger }} onClick={() => del(b.id)}>삭제</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <div style={s.overlay}>
          <div style={s.modal}>
            <div style={s.modalTitle}>{editId ? '배너 수정' : '배너 추가'}</div>
            <div style={s.mFields}>
              <div style={s.mf}><label style={s.ml}>제목</label>
                <input style={s.mi} value={form.title} onChange={e => setForm(p => ({ ...p, title: e.target.value }))} placeholder="배너 제목" />
              </div>
              <div style={s.mf}><label style={s.ml}>썸네일 이미지 URL</label>
                <input style={s.mi} value={form.imageUrl || ''} onChange={e => setForm(p => ({ ...p, imageUrl: e.target.value }))} placeholder="https://..." />
                {form.imageUrl && <img src={form.imageUrl} alt="preview" style={{ marginTop: 8, maxHeight: 80, borderRadius: 6, objectFit: 'cover' }} onError={e => e.target.style.display = 'none'} />}
              </div>
              <div style={s.mf}><label style={s.ml}>웹 URL</label>
                <input style={s.mi} value={form.url || ''} onChange={e => setForm(p => ({ ...p, url: e.target.value }))} placeholder="/event/1 또는 https://..." />
              </div>
              <div style={s.mf}><label style={s.ml}>모바일 URL (선택)</label>
                <input style={s.mi} value={form.mobileUrl || ''} onChange={e => setForm(p => ({ ...p, mobileUrl: e.target.value }))} placeholder="다를 경우 입력" />
              </div>
              <div style={{ display: 'flex', gap: 12 }}>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>순서</label>
                  <input type="number" style={s.mi} value={form.order} onChange={e => setForm(p => ({ ...p, order: +e.target.value }))} />
                </div>
                <div style={{ ...s.mf, flex: 1 }}><label style={s.ml}>노출</label>
                  <select style={s.mi} value={form.visible} onChange={e => setForm(p => ({ ...p, visible: e.target.value }))}>
                    <option value="Y">Y</option><option value="N">N</option>
                  </select>
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
  total: { fontSize: 13, color: '#555' }, headerBtns: { display: 'flex', gap: 10 },
  tableWrap: { background: '#fff', borderRadius: 12, overflow: 'auto', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' },
  table: { width: '100%', borderCollapse: 'collapse' },
  th: { padding: '11px 12px', textAlign: 'left', fontSize: 12, color: '#888', fontWeight: 600, background: '#fafafa', borderBottom: '1px solid #f0f0f0', whiteSpace: 'nowrap' },
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', borderRadius: 16, padding: 32, width: 520, boxShadow: '0 20px 60px rgba(0,0,0,0.2)' },
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
  badge: { padding: '3px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600 },
  btnSm: { padding: '4px 10px', background: '#f0f2f5', border: 'none', borderRadius: 6, fontSize: 12, cursor: 'pointer', marginRight: 4 },
  btnDanger: { background: '#fff0f0', color: '#e53e3e' },
  orderBtns: { display: 'flex', gap: 4 },
  orderBtn: { padding: '2px 8px', background: '#f0f2f5', border: 'none', borderRadius: 4, fontSize: 11, cursor: 'pointer' },
}
