import { Modal, Button, Form, Row, Col } from 'react-bootstrap'
import BootstrapTable from "react-bootstrap-table-next";
import { useState, useEffect } from "react";
import "./CustomerDescription.css"
import { Component } from "react";

export default class CustomerDescription extends Component {
	constructor(props) {
		super(props);
		this.setCustomerDescription = props.setCustomerDescription;
		this.state = {
			id: props.id,
			action: props.action,
			info: {},
			validated: false,
		}

		this.handleInputChange = this.handleInputChange.bind(this);
		this.handleSubmit = this.handleSubmit.bind(this);

		if (this.state.action !== "Edit") {
			return;
		}
		fetch("/get/customer?id=" + this.state.id)
		.then((response) => {
			if (response.ok) {
			return response.json()
			}
			throw response
		})
		.then((data) => { 
			console.log(data); 
			this.setState({
				info: data,
			})
		})
		.catch((error) => {
			console.error("Error fetching data: ", error);
		})
	}

    columns = [
        { dataField: "ID", text: "Customer ID"},
        { dataField: "Username", text: "Username"},
        { dataField: "Phone", text: "Phone number"},
        { dataField: "Fname", text: "First name"},
        { dataField: "Lname", text: "Last name"},
        { dataField: "Email", text: "Email"},
        { dataField: "Bdate", text: "Birthdate"},
        { dataField: "IdNum", text: "ID number"},
        { dataField: "FamScore", text: "Familiarity point"},
    ]

    handleInputChange = (event) => {
        const target = event.target;
        const value = target.type === 'checkbox' ? target.checked : target.value;
        const name = target.name;
		this.state.info[name] = value;
		this.setState({
			info: this.state.info
		})
    }

    isInt(value) {
        return !isNaN(value) && 
               parseInt(Number(value)) == value && 
               !isNaN(parseInt(value, 10));
    }
    
    handleSubmit = (event) => {
        const form = event.currentTarget;
        if (!this.isInt(form.FamScore.value)) {
          alert("Familiarity point much be number!")
          event.stopPropagation();
          event.preventDefault();
          return
        }
		this.setState({
			validated: true,
		})
        if (form.checkValidity() === false) {
          event.preventDefault();
          event.stopPropagation();
        } else {
          var query = this.state.action === "Edit" ? "/edit/customer" : "/add/customer"
          const requestOptions = {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(this.state.info)
          };
          fetch(query, requestOptions)
            .then(response => {
              if (response.ok) {
                this.setCustomerDescription(-1)
              } else {
                response.text().then(text => { alert(text); })
              }
            })
        }
    };

	render() {
    return (
        <div className="popup-background">
        <Modal.Dialog className="popup modal-dialog-scrollable" size="lg">
            <Modal.Header closeButton onClick={() => this.setCustomerDescription(-1)}>
                <Modal.Title>{this.state.action}</Modal.Title>
            </Modal.Header>
            <Modal.Body className="body-popup">
                <Form noValidate validated={this.validated} onSubmit={this.handleSubmit}>
                <Row className="mb-3">
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="ID" attrName="Customer ID" required={true} md="4" disable={this.state.action === 'Edit'} />
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="Username" attrName="Username" required={true} md="4" disable={this.state.action === 'Edit'} />
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="Passwd" attrName="Password" required={true} md="4" />
                </Row>
                <Row className="mb-3">
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="Phone" attrName="Phone number" required={true} md="4" />
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="Fname" attrName="First name" md="4" required={true} />
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="Lname" attrName="Last name" md="4" required={true} />
                </Row>
                <Row className="mb-3">
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="Email" attrName="Email" md="4" disable={this.state.action === 'Edit'} />
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="Bdate" attrName="Birthdate" md="4" required={true} />
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="IdNum" attrName="ID number" required={true} md="4" />
                </Row>
                <Row className="mb-3">
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="FamScore" attrName="Familiarity point" md="6" required={true} />
                    {this.state.action === 'Edit' ? 
                    <InputGroupCustom info={this.state.info} handleInputChange={this.handleInputChange} attr="Num_ref" attrName="Number of Recommendees" md="6" required={true} disable={true}/> :
                    <p/>}
                </Row>
                {/* <Form.Group as={Col} md="12">
                    <Form.Label>List of recommendees:</Form.Label>
                    <table class="table table-striped">
                        <thead>
                            <tr>
                            {this.columns.map((item, i) => (
                                <th name={item.dataField}>
                                    {item.text}
                                </th>
                            ))}
                            </tr>
                        </thead>
                        <tbody>
                            {this.state.info["Recommendee"].map((item, i) =>  (
								<tr>
									{this.columns.map((colitem) => (
										<td>{item[colitem]}</td>
									))}
								</tr>
							))}
                        </tbody>
                    </table>
                </Form.Group> */}
				<div className="table-custom">
					{/* https://react-bootstrap-table.github.io/react-bootstrap-table2/docs/about.html  */}
					<BootstrapTable keyField="id" data={this.state.info["Recommendee"]} columns={this.columns}/>
				</div>
                <Modal.Footer>
                    <Button type="submit">Save Changes</Button>
                </Modal.Footer>
                </Form>
            </Modal.Body>
        </Modal.Dialog>
        </div>
    )}
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