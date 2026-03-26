// const token: string = 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253QGdtYWlsLmNvbSIsImlhdCI6MTc3MzM3ODYxNSwiZXhwIjoxNzczNDY1MDE1fQ.u1AN_G6zZ4vhmYrFgO32OtShjQpGwHivWWOJJJPpXg90Ie4rq6jLf-k9UFRqJni1_Q_qi40-zZU7pVOA6rFb6w'    // admin
const token: string = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253MkBnbWFpbC5jb20iLCJpYXQiOjE3NzQ0NDIwMDEsImV4cCI6MTc3NDUyODQwMX0.FpcMyuaNoER74k7T0_L__s_fYhWkKs6ewFAasVYZAPgNEwoQ3N62tBvHPgB2iWSIb6bbWty4-rRTCwtHVELYlA"    // student

async function createStudent() {
  const res = await fetch("http://136.116.64.6/api/announcements/all", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    }
  });
  if (res.ok) {
    const data = await res.json();
    console.log(data);
  } else {
    console.error(res.status)
  }
}

export default async function test() {

    await createStudent();

    return (
        <div>
            <h1>Test Page</h1>
        </div>
    )
}