// const token: string = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253QGdtYWlsLmNvbSIsImlhdCI6MTc3NTEwMDY1OCwiZXhwIjoxNzc1MTg3MDU4fQ.ZQkj6I10sSnVn9wGB5CVFQwypOYTvyHFJ5rDVPAhYEM5bc61BfVesDkPtK9Hvt1LBUsyuhhGT7VHdYfNoOGS0Q"    // admin
const token: string = "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhM253MkBnbWFpbC5jb20iLCJpYXQiOjE3NzUxMDIxNTcsImV4cCI6MTc3NTE4ODU1N30.7HrjsiakW3KXD-5v-VLCfpRFvr1gNIk8QBzGVje4IayRu63H-Sq2m8lsNlP5WiLAzGUFNYKLTFquGby3GRRDeQ"    // student

async function testFunc() {
  const res = await fetch("http://136.116.64.6/api/announcements", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    // body: JSON.stringify({
    //   "title": "Test Announcement(student)",
    //   "content": "This is a test announcement created for testing purposes. I think this is a very important announcement that everyone should read. Please make sure to read it carefully and share it with your friends and family. Thank you for your attention. Lol I just need to fill up the body with some text to make it look more realistic. I hope this announcement will be useful for everyone who reads it. Have a great day! ",
    //   "targetRole": "STUDENT",
    //   "targetClassGroupId": 1,
    //   "important": true,
    //   "expiresAt": "2026-04-30T04:29:52.626Z"
    // })
  });
  if (res.ok) {
    const data = await res.json();
    console.log(data);
  } else {
    console.error(res.status)
  }
}

export default async function test() {

    await testFunc();

    return (
        <div>
            <h1>Test Page</h1>
        </div>
    )
}