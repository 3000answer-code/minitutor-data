import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useState } from 'react'
import LoginPage from './pages/LoginPage'
import Layout from './components/Layout'
import Dashboard from './pages/Dashboard'
import MemberList from './pages/members/MemberList'
import MemberPayments from './pages/members/MemberPayments'
import MemberStats from './pages/members/MemberStats'
import InstructorList from './pages/videos/InstructorList'
import SeriesList from './pages/videos/SeriesList'
import VideoList from './pages/videos/VideoList'
import VideoStats from './pages/videos/VideoStats'
import LectureQA from './pages/videos/LectureQA'
import ConsultExperts from './pages/consultation/ConsultExperts'
import ConsultList from './pages/consultation/ConsultList'
import NoticeList from './pages/notice/NoticeList'
import EventList from './pages/notice/EventList'
import FaqList from './pages/support/FaqList'
import InquiryList from './pages/support/InquiryList'
import CouponList from './pages/coupon/CouponList'
import BannerManage from './pages/admin/BannerManage'
import AdminList from './pages/admin/AdminList'
import PushSend from './pages/admin/PushSend'

function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false)
  const [adminInfo, setAdminInfo] = useState(null)

  const handleLogin = (info) => {
    setAdminInfo(info)
    setIsLoggedIn(true)
  }

  const handleLogout = () => {
    setIsLoggedIn(false)
    setAdminInfo(null)
  }

  if (!isLoggedIn) return <LoginPage onLogin={handleLogin} />

  return (
    <BrowserRouter>
      <Layout adminInfo={adminInfo} onLogout={handleLogout}>
        <Routes>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/members" element={<MemberList />} />
          <Route path="/members/payments" element={<MemberPayments />} />
          <Route path="/members/stats" element={<MemberStats />} />
          <Route path="/videos/instructors" element={<InstructorList />} />
          <Route path="/videos/series" element={<SeriesList />} />
          <Route path="/videos/list" element={<VideoList />} />
          <Route path="/videos/stats" element={<VideoStats />} />
          <Route path="/videos/qa" element={<LectureQA />} />
          <Route path="/consultation/experts" element={<ConsultExperts />} />
          <Route path="/consultation/list" element={<ConsultList />} />
          <Route path="/notice/list" element={<NoticeList />} />
          <Route path="/notice/events" element={<EventList />} />
          <Route path="/support/faq" element={<FaqList />} />
          <Route path="/support/inquiry" element={<InquiryList />} />
          <Route path="/coupon" element={<CouponList />} />
          <Route path="/admin/banners" element={<BannerManage />} />
          <Route path="/admin/list" element={<AdminList />} />
          <Route path="/admin/push" element={<PushSend />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  )
}

export default App
