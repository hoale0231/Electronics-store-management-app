import BootstrapTable from "react-bootstrap-table-next";
import { Button, Form, Row, Col, FloatingLabel } from 'react-bootstrap'
import { useState, useEffect } from "react";
import StaffDescription from "./StaffDescription";


export default function Staff() {
  const [staffDescription, setstaffDescription] = useState(-1)
  const [staffs, setStaffs] = useState([]);


  const columns = [
    { dataField: "ID", text: "staff ID", },
    { dataField: "Username", text: "Username", },
    { dataField: "Passwd", text: "Password", },
    { dataField: "IdNum", text: "ID number", },
    { dataField: "Phone", text: "Phone number", },
    { dataField: "Salary", text: "Salary", },
    { dataField: "Bdate", text: "Birthdate", },
    { dataField: "Fname", text: "First name", },
    { dataField: "Lname", text: "Last name", },
    { dataField: "Email", text: "Email", },
    { dataField: "Addr", text: "Address", },
    { dataField: "ID_branch", text: "ID branch", }
  ];

  useEffect(() => {
    fetch("/api/staff/all")
      .then((response) => {
        if (response.ok) {
          return response.json()
        }
        throw response
      })
      .then((data) => { setStaffs(data); })
      .catch((error) => {
        console.error("Error fetching data: ", error);
      })
  }, [])

  const deleteStaff = function (id) {
    fetch("/api/staff/remove?id=" + id, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    })
      .then((response) => {
        if (response.ok) {
          const index = staffs.findIndex((e => e.id === id))
          staffs.splice(index, 1)
          setStaffs(staffs)
          setstaffDescription(-1)
          return response.json()
        }
        throw response
      })

  }

  const rowEvents = {
    onClick: (e, row, rowIndex) => {
      setstaffDescription(row.ID)
    },
  };




  return (
    <div className="popup_container">
      <Button className="customButton" variant="success" onClick={() => { setstaffDescription(0) }}>Add staff</Button>

      <div className="table-custom">
        {/* https://react-bootstrap-table.github.io/react-bootstrap-table2/docs/about.html  */}
        <BootstrapTable keyField="id" data={staffs} columns={columns} rowEvents={rowEvents} />
      </div>
      {/* <div className="container">
        <Button variant="success" onClick={() => { loadData(false) }}>Load More</Button>
      </div> */}
      <div>
        {staffDescription === -1 ? <p /> : staffDescription === 0 ?
          <StaffDescription id={staffDescription} setstaffDescription={setstaffDescription} action={'Add'} /> :
          <StaffDescription id={staffDescription} setstaffDescription={setstaffDescription} deleteStaff={deleteStaff} action={'Edit'} />}
      </div>
    </div>
  );
}

