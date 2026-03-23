// const token: string = 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253QGdtYWlsLmNvbSIsImlhdCI6MTc3MzM3ODYxNSwiZXhwIjoxNzczNDY1MDE1fQ.u1AN_G6zZ4vhmYrFgO32OtShjQpGwHivWWOJJJPpXg90Ie4rq6jLf-k9UFRqJni1_Q_qi40-zZU7pVOA6rFb6w'    // admin
const token: string = 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253MkBnbWFpbC5jb20iLCJpYXQiOjE3NzMzNzY4MzIsImV4cCI6MTc3MzQ2MzIzMn0.YGk6RNR6pPkZXZwHE5D8WkNsW0y7ceRnOV0e1l1R0HQc1iT47vBvR7zxc3QDDXI4y57gNkDU_R5OaRXtZY42Qw'    // student

async function createStudent() {
  const res = await fetch("http://136.116.64.6/api/invoices/debt/26", {
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