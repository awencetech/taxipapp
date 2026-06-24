const express = require('express');
const router = express.Router();
const {
  createTicket,
  getTickets,
  getMyTickets,
  getTicket,
  updateTicket,
  addMessage
} = require('../controllers/supportTicketController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

router.route('/')
  .post(createTicket)
  .get(authorize('admin'), getTickets);

router.route('/my-tickets').get(getMyTickets);
router.route('/:id')
  .get(getTicket)
  .put(updateTicket);

router.route('/:id/messages').post(addMessage);

module.exports = router;
