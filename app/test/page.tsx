// const token: string = 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253QGdtYWlsLmNvbSIsImlhdCI6MTc3MjcwMTgyMiwiZXhwIjoxNzcyNzg4MjIyfQ.0A_85Ahu6kLrOQeS5iZuX6w7DqEG5G5RSP53uN54LgCFfCwwPXywfJJQ-7IykvvI78C2WxDItZGtjTOoU71Ynw'    // admin
const token: string = 'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253MkBnbWFpbC5jb20iLCJpYXQiOjE3NzI3MDUxMDQsImV4cCI6MTc3Mjc5MTUwNH0.d9iD7eDCdvLoAKlPblfFWpJynkq-89FVgLW7Q-kp6UuLJXdVqEtvcRLwEsn_o5vlclu0x4bsh4UxsME5RypPNw'    // student

async function createStudent() {
  const res = await fetch("http://136.116.64.6/api/attendance/stats", {
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

export default async function tst() {

    await createStudent();

    return (
        <div>
            <h1>Test Page</h1>
        </div>
    )
}