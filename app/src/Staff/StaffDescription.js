import { Modal, Button, Form, Row, Col } from 'react-bootstrap'
import { useState, useEffect } from "react";
import "./StaffDescription.css"

var number = /^-?\d+$/;

export default function StaffDescription(props) {
  const { id, setstaffDescription, deleteStaff, action } = props
  const [info, setInfo] = useState({})

  useEffect(() => {
    if (action !== "Edit") {
      return;
    }
    fetch("/api/staff/info?id=" + id)
      .then((response) => {
        if (response.ok) {
          return response.json()
        }
        throw response
      })
      .then((data) => { console.log(data); setInfo(data) })
      .catch((error) => {
        console.error("Error fetching data: ", error);
      })
  }, [id, action])

  const [validated, setValidated] = useState(false);

  const handleSubmit = (event) => {
    const form = event.currentTarget;
    if (!number.test(form.Salary.value)) {
      alert("Import salary much be number!")
      event.stopPropagation();
      event.preventDefault();
      return
    }
    setValidated(true);
    if (form.checkValidity() === false) {
      event.preventDefault();
      event.stopPropagation();
    } else {
      var query = action === "Edit" ? "/api/staff/update" : "/api/staff/add"
      const requestOptions = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(info)
      };
      fetch(query, requestOptions)
        .then(response => {
          if (response.ok) {
            setstaffDescription(-1)
          } else {
            response.text().then(text => { alert(text); })
          }
        })
    }
  };

  const handleInputChange = (event) => {
    const target = event.target;
    const value = target.type === 'checkbox' ? target.checked : target.value;
    const name = target.name;
    info[name] = value;
    // if (name === "ProdType") setProdType(value)
  }


  return (
    <div className="popup-background">
      <Modal.Dialog className="popup" size="lg">
        <Modal.Header closeButton onClick={() => setstaffDescription(-1)}>
          <Modal.Title>{action}</Modal.Title>
        </Modal.Header>

        <Modal.Body className="body-popup">
          <Form noValidate validated={validated} onSubmit={handleSubmit}>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID" attrName="ID" required={true} md="4" disable={action === 'Edit'} />
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Username" attrName="Username" required={true} md="4" disable={action === 'Edit'} />
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Passwd" attrName="Password" required={true} md="4" />
            </Row>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="IdNum" attrName="ID number" required={true} md="4" />
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Phone" attrName="Phone number" required={true} md="4" />
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Salary" attrName="Salary" md="4" required={true} />
            </Row>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Bdate" attrName="Birthdate" md="4" required={true} />
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Fname" attrName="First name" md="4" required={true} />
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Lname" attrName="Last name" md="4" required={true} />
            </Row>
            <Row className="mb-3">
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Email" attrName="Email" md="5" disable={action === 'Edit'} />
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="Addr" attrName="Address" md="5" required={true} />
              <InputGroupCustom info={info} handleInputChange={handleInputChange} attr="ID_branch" attrName="ID branch" md="2" required={true} />
            </Row>
            <Modal.Footer>
              <Button type="submit">Save Changes</Button>
              {action === 'Edit' ? <Button variant="danger" onClick={() => { deleteStaff(id); }}>Delete Staff</Button> : <p />}
            </Modal.Footer>
          </Form>
        </Modal.Body>

      </Modal.Dialog>
    </div>
  )
}


function InputGroupCustom(props) {
  const { info, attr, attrName, required, handleInputChange, md, disable } = props
  return (
    <Form.Group as={Col} md={md}>
      <Form.Label>{attrName}</Form.Label>
      <Form.Control
        required={required}
        disabled={disable}
        name={attr}
        type="text"
        defaultValue={info[attr]}
        onChange={handleInputChange}
      />
      <Form.Control.Feedback type="invalid">
        Invalid {attr}
      </Form.Control.Feedback>
    </Form.Group>
  )
}